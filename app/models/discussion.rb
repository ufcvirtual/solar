class Discussion < Event

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :schedule

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  has_many :discussion_posts, class_name: "Post", through: :academic_allocations
  has_many :allocations, through: :allocation_tag

  validates :name, :description, presence: true
  validates :name, length: {maximum: 120}

  validate :unique_name, unless: "allocation_tags_ids.nil?"
  validate :check_final_date_presence

  accepts_nested_attributes_for :schedule

  attr_accessible :name, :description, :schedule_attributes, :schedule_id
  attr_accessor :allocation_tags_ids

  before_destroy :can_destroy?
  after_destroy :delete_schedule

  def can_destroy?
    discussion_posts.empty?
  end

  def delete_schedule
    self.schedule.destroy
  end

  def check_final_date_presence
    if schedule.end_date.nil?
      errors.add(:final_date_presence, I18n.t(:mandatory_final_date, scope: [:discussions, :error]))
      return false
    end
  end

  # verifica se existe alguma academic_allocation de um fórum com o mesmo nome cuja allocation_tag coincida com alguma das allocation_tags que o fórum está sendo cadastrado
  # Ex:
  # => Existe o fórum Fórum 1 com academic allocation para a allocation_tag 3
  # => Se eu criar um novo fórum em que uma de suas allocation_tags seja a 3 e tenha o mesmo nome que o Fórum 1, é pra dar erro
  def unique_name
    discussions_with_same_name = Discussion.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}, name: name)
    errors.add(:name, I18n.t(:existing_name, scope: [:discussions, :error])) if (@new_record == true or name_changed?) and discussions_with_same_name.size > 0
  end

  def opened?
    schedule.end_date.nil? ? (schedule.start_date.to_date <= Date.today) : Date.today.between?(schedule.start_date.to_date, schedule.end_date.to_date)
  end

  def closed?
    schedule.end_date.nil? ? false : (schedule.end_date.to_date < Date.today)
  end

  def extra_time?(user_id)
    ((self.allocation_tags.map {|at| at.is_observer_or_responsible?(user_id)}).include?(true) and self.closed?) ?
      ((self.schedule.end_date.to_date + Discussion_Responsible_Extra_Time) >= Date.today) : false
  end

  def user_can_interact?(user_id)
    ((opened? and not(closed?)) or extra_time?(user_id)) # considerando os nao iniciados
  end

  def posts(opts = {}, allocation_tags_ids = nil)
    opts = { "type" => 'new', "order" => 'desc', "limit" => Rails.application.config.items_per_page.to_i,
      "display_mode" => 'list', "page" => 1 }.merge(opts)
    type = (opts["type"] == 'history' ) ? '<' : '>'
    
    query = []
    query << "updated_at::timestamp(0) #{type} '#{opts["date"]}'::timestamp(0)" if opts.include?('date') and (not opts['date'].blank?)
    query << "parent_id IS NULL" unless opts["display_mode"] == 'list'

    posts_by_allocation_tags_ids(allocation_tags_ids).where(query).order("updated_at #{opts["order"]}").limit("#{opts['limit']}").offset("#{(opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i}")
  end

  def discussion_posts_count(plain_list = true, allocation_tags_ids = nil)
    (plain_list ? posts_by_allocation_tags_ids(allocation_tags_ids).count : posts_by_allocation_tags_ids(allocation_tags_ids).where(parent_id: nil).count)
  end

  def count_posts_after_and_before_period(period, allocation_tags_ids = nil)
    [{"before" => count_posts_before_period(period, allocation_tags_ids),
      "after" => count_posts_after_period(period, allocation_tags_ids)}]
  end

  def count_posts_before_period(period, allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids).where("updated_at::timestamp(0) < '#{period.first.to_time}'::timestamp(0)").count 
  end

  def count_posts_after_period(period, allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids).where("updated_at::timestamp(0) > '#{period.last.to_time}'::timestamp(0)").count
  end

  def self.posts_count_by_user(student_id, allocation_tag_id)
    joins(:schedule, academic_allocations: :allocation_tag)
      .joins("LEFT JOIN discussion_posts AS dp ON dp.academic_allocation_id = academic_allocations.id AND dp.user_id = #{student_id}")
      .where(allocation_tags: {id: AllocationTag.find(allocation_tag_id).related}).select("discussions.id, discussions.name, COUNT(dp.id) AS posts_count, schedules.start_date AS start_date")
      .group("discussions.id, discussions.name, start_date").order("start_date").uniq
  end

  def self.all_by_allocation_tags(allocation_tag_id)
    joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: AllocationTag.find(allocation_tag_id).related})
      .select("discussions.*, academic_allocations.id AS ac_id")
      .order("schedules.start_date, schedules.end_date, name")
  end

  # devolve a lista com todos os posts de uma discussion em ordem decrescente de updated_at, apenas o filho mais recente de cada post será adiconado à lista
  def latest_posts(allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids).select("DISTINCT ON (updated_at, parent_id) updated_at, parent_id, level")
  end

  def can_remove_or_unbind_group?(group)
    discussion_posts.empty? # não pode dar unbind nem remover se fórum possuir posts
  end

  def posts_by_allocation_tags_ids(allocation_tags_ids = nil)
    allocation_tags_ids = AllocationTag.where(id: allocation_tags_ids).map(&:related).flatten.compact.uniq unless allocation_tags_ids.nil?
    posts = discussion_posts
    posts = posts.joins(academic_allocation: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}) unless allocation_tags_ids.nil?
    posts
  end

  def resume(allocation_tags_ids = nil)
    {
      id: id,
      description: description,
      name: name,
      last_post_date: latest_posts(allocation_tags_ids).first.try(:updated_at).try(:to_s, :db),
      status: status,
      start_date: schedule.start_date.try(:to_s, :db),
      end_date: schedule.end_date.try(:to_s, :db)
    }
  end

  def status
    return "2" if closed?
    return "1" if opened?
    return "0" # nao iniciado
  end

  def last_post_date(allocation_tags_ids = nil)
    latest_posts(allocation_tags_ids).first.try(:updated_at)
  end

end

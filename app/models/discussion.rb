class Discussion < Event

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :schedule

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  has_many :discussion_posts, class_name: "Post", foreign_key: "discussion_id"
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
    ((self.allocation_tags.map {|at| at.is_user_class_responsible?(user_id)}).include?(true) and self.closed?) ?
      ((self.schedule.end_date.to_date + Discussion_Responsible_Extra_Time) >= Date.today) : false
  end

  def user_can_interact?(user_id)
    ((opened? and not(closed?)) or extra_time?(user_id)) # considerando os nao iniciados
  end

  def posts(opts = {})
    opts = { "type" => 'news', "order" => 'desc', "limit" => Rails.application.config.items_per_page.to_i,
      "display_mode" => 'list', "page" => 1 }.merge(opts)
    type = (opts["type"] == 'news') ? '>' : '<'
    innder_order = (opts["type"] == 'news') ? 'asc' : 'desc'

    query = []
    query << "updated_at::timestamp(0) #{type} '#{opts["date"]}'::timestamp(0)" if opts.include?('date')
    query << "parent_id IS NULL" unless opts["display_mode"] == 'list'

    discussion_posts.where(query).order("updated_at #{innder_order}").limit("#{opts['limit']}").offset("#{(opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i}")
  end

  def discussion_posts_count(plain_list = true)
    (plain_list ? self.discussion_posts.count : self.discussion_posts.where(parent_id: nil).count)
  end

  def count_posts_after_and_before_period(period)
    [{"before" => count_posts_before_period(period),
      "after" => count_posts_after_period(period)}]
  end

  def count_posts_before_period(period)
    discussion_posts.where("updated_at::timestamp(0) < '#{period.first}'").count 
  end

  def count_posts_after_period(period)
    discussion_posts.where("updated_at::timestamp(0) > '#{period.last}'").count
  end

  def self.posts_count_by_user(student_id, allocation_tags)
    discussions = joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags})
    discussions.select("discussions.id AS discussion_id, discussions.name, COUNT(dp.id) AS qtd")
      .joins("LEFT JOIN discussion_posts AS dp ON dp.discussion_id = discussions.id AND dp.user_id = #{student_id}").group("discussions.id, discussions.name").uniq
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).order("schedules.start_date, schedules.end_date, name")
  end

  # devolve a lista com todos os posts de uma discussion em ordem decrescente de updated_at, apenas o filho mais recente de cada post será adiconado à lista
  def latest_posts
    discussion_posts.select("DISTINCT ON (updated_at, parent_id) updated_at, parent_id, level")
  end

  def can_remove_or_unbind_group?(group)
    discussion_posts.empty? # não pode dar unbind nem remover se fórum possuir posts
  end

  def resume
    {
      id: id,
      description: description,
      name: name,
      last_post_date: latest_posts.first.try(:updated_at).try(:to_s, :db),
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

  def last_post_date
    latest_posts.first.try(:updated_at).try(:to_s, :db)
  end

end

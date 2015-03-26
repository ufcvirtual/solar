class Discussion < Event
  include AcademicTool

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :schedule

  has_many :discussion_posts, class_name: 'Post', through: :academic_allocations
  has_many :allocations, through: :allocation_tag

  before_destroy :can_destroy?
  after_destroy :delete_schedule

  validates :name, :description, presence: true
  validates :name, length: { maximum: 120 }

  validate :unique_name
  validate :check_final_date_presence

  accepts_nested_attributes_for :schedule

  def can_destroy?
    discussion_posts.empty?
  end

  def delete_schedule
    self.schedule.destroy
  end

  def check_final_date_presence
    if schedule.end_date.nil?
      errors.add(:final_date_presence, I18n.t('discussions.error.mandatory_final_date'))
      return false
    end
  end

  # verifica se existe alguma academic_allocation de um forum com o mesmo nome cuja allocation_tag coincida com alguma das allocation_tags que o forum esta sendo cadastrado
  # Ex:
  # => Existe o forum Fórum 1 com academic allocation para a allocation_tag 3
  # => Se eu criar um novo forum em que uma de suas allocation_tags seja a 3 e tenha o mesmo nome que o Forum 1, é pra dar erro
  def unique_name
    discussions_with_same_name = self.class.joins(:allocation_tags).where(allocation_tags: { id: allocation_tag_ids_associations || academic_allocations.map(&:allocation_tag_id) }, name: name)
    errors.add(:name, I18n.t('discussions.error.existing_name')) if (@new_record == true || name_changed?) && discussions_with_same_name.size > 0
  end

  def statuses(user_id = nil)
    status = []

    if schedule.end_date.nil?
      status << (schedule.start_date.to_date <= Date.today ? ['opened', 'can_interact'] : 'will_open')
    elsif schedule.end_date.to_date < Date.today
      status << 'closed'
      status << ['extra_time', 'can_interact'] if (!user_id.nil? && (User.find(user_id).get_allocation_tags_ids_from_profiles(true, true) & allocation_tags.pluck(:id)).any? && (schedule.end_date.to_date + Discussion_Responsible_Extra_Time) >= Date.today)
    elsif schedule.start_date.to_date <= Date.today
      status << ['opened', 'can_interact']
    end

    status.flatten
  end

  def user_can_interact?(user_id)
    statuses(user_id).include?('can_interact')
  end

  def posts(opts = {}, allocation_tags_ids = nil)
    opts = { 'type' => 'new', 'order' => 'desc', 'limit' => Rails.application.config.items_per_page.to_i,
      'display_mode' => 'list', 'page' => 1 }.merge(opts)
    type = (opts['type'] == 'history' ) ? '<' : '>'

    query = []
    query << "updated_at::timestamp(0) #{type} '#{opts["date"]}'::timestamp(0)" if opts.include?('date') && (!opts['date'].blank?)
    query << 'parent_id IS NULL' unless opts['display_mode'] == 'list'

    offset = (opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i

    posts_by_allocation_tags_ids(allocation_tags_ids, { grandparent: false, query: query.join(' AND '),
                                                        order: "updated_at #{opts['order']}", limit: opts['limit'],
                                                        offset: offset })
  end

  def discussion_posts_count(plain_list = true, allocation_tags_ids = nil)
    (plain_list ? posts_by_allocation_tags_ids(allocation_tags_ids, { grandparent: false }).count : posts_by_allocation_tags_ids(allocation_tags_ids).collect{ |a| a if a.parent.nil? }.compact.count)
  end

  def count_posts_after_and_before_period(period, allocation_tags_ids = nil)
    [{ 'before' => count_posts_before_period(period, allocation_tags_ids),
       'after' => count_posts_after_period(period, allocation_tags_ids) }]
  end

  def count_posts_before_period(period, allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids, { query: "date_trunc('seconds', updated_at) < '#{period.first}'" } ).count # trunc seconds - discard miliseconds
  end

  def count_posts_after_period(period, allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids, { query: "date_trunc('seconds', updated_at) > '#{period.last}'" } ).count
  end

  # devolve a lista com todos os posts de uma discussion em ordem decrescente de updated_at, apenas o filho mais recente de cada post sera adiconado a lista
  def latest_posts(allocation_tags_ids = nil)
    posts_by_allocation_tags_ids(allocation_tags_ids, { select: 'DISTINCT ON (updated_at, parent_id) updated_at, parent_id, level' } )
  end

  def can_remove_groups?(groups)
    discussion_posts.empty? # nao pode dar unbind nem remover se forum possuir posts
  end

  def posts_by_allocation_tags_ids(allocation_tags_ids = nil, opt = { grandparent: true, query: '', order: 'updated_at desc', limit: nil, offset: nil, select: 'discussion_posts.*' } )
    allocation_tags_ids = AllocationTag.where(id: allocation_tags_ids).map(&:related).flatten.compact.uniq
    posts_list = discussion_posts.where(opt[:query]).order(opt[:order]).limit(opt[:limit]).offset(opt[:offset]).select(opt[:select])
    posts_list = posts_list.joins(academic_allocation: :allocation_tag).where(allocation_tags: { id: allocation_tags_ids }) unless allocation_tags_ids.blank?
    (opt[:grandparent] ? posts_list.map(&:grandparent).uniq.compact : posts_list.compact.uniq)
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

  def status(user = nil)
    discussion_status = statuses(user)
    return '1' if discussion_status.include?('opened') || discussion_status.include?('extra_time')
    return '2' if discussion_status.include?('closed')
    return '0' # nao iniciado
  end

  def last_post_date(allocation_tags_ids = nil)
    latest_posts(allocation_tags_ids).first.try(:updated_at)
  end

  def self.posts_count_by_user(student_id, allocation_tag_id)
    joins(:schedule, academic_allocations: :allocation_tag)
      .joins("LEFT JOIN discussion_posts AS dp ON dp.academic_allocation_id = academic_allocations.id AND dp.user_id = #{student_id}")
      .where(allocation_tags: { id: AllocationTag.find(allocation_tag_id).related }).select('discussions.id, discussions.name, COUNT(dp.id) AS posts_count, schedules.start_date AS start_date')
      .group('discussions.id, discussions.name, start_date').order('start_date').uniq
  end

  def self.all_by_allocation_tags(allocation_tag_id)
    joins(:schedule, academic_allocations: :allocation_tag).joins('LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id')
      .where(allocation_tags: { id: AllocationTag.find(allocation_tag_id).related })
      .select('discussions.*, academic_allocations.id AS ac_id, COUNT(discussion_posts.id) AS posts_count, schedules.start_date AS start_date, schedules.end_date AS end_date')
      .group('discussions.id, schedules.start_date, schedules.end_date, name, academic_allocations.id')
      .order('start_date, end_date, name')
  end

end

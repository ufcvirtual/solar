class Discussion < Event
  include AcademicTool
  include EvaluativeTool
  include FilesHelper

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :schedule

  has_many :discussion_posts, class_name: 'Post', through: :academic_allocations
  has_many :allocations, through: :allocation_tag
  has_many :enunciation_files, class_name: 'DiscussionEnunciationFile', dependent: :destroy

  before_destroy :can_remove_groups_with_raise
  after_destroy :delete_schedule

  validates :name, :description, presence: true
  validates :name, length: { maximum: 120 }

  validate :unique_name
  validate :check_final_date_presence

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :enunciation_files, allow_destroy: true, reject_if: proc { |attributes| !attributes.include?(:attachment) || attributes[:attachment] == '0' || attributes[:attachment].blank? }

  def delete_schedule
    self.schedule.destroy
  end

  def check_final_date_presence
    if schedule.end_date.nil?
      errors.add(:final_date_presence, I18n.t('discussions.error.mandatory_final_date'))
      return false
    end
  end

  def copy_dependencies_from(discussion_to_copy)
    unless discussion_to_copy.enunciation_files.empty?
      discussion_to_copy.enunciation_files.each do |file|
        new_file = DiscussionEnunciationFile.create! file.attributes.merge({ discussion_id: self.id })
        copy_file(file, new_file, File.join(['discussion', 'enunciation']))
      end
    end
  end

  def started?
    schedule.start_date.to_date <= Date.today
  end

  def in_time?
    started? && schedule.end_date.to_date >= Date.today
  end

  # Verifica se existe alguma ac para um forum de mesmo nome cuja allocation_tag esteja entre as allocation_tags informadas
  # Ex:
  # => Existe o forum Forum 1 com academic allocation para a allocation_tag 3
  # => Se eu criar um novo forum em que uma de suas allocation_tags seja a 3 e tenha o mesmo nome que o Forum 1, eh pra dar erro
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
      status << ['extra_time', 'can_interact'] if !user_id.nil? && (User.find(user_id).get_allocation_tags_ids_from_profiles(true, true) & allocation_tags.pluck(:id)).any? && (schedule.end_date.to_date + Discussion_Responsible_Extra_Time) >= Date.today
    elsif schedule.start_date.to_date <= Date.today
      status << ['opened', 'can_interact']
    end

    status.flatten
  end

  def user_can_interact?(user_id)
    statuses(user_id).include?('can_interact')
  end

  def posts(opts = {}, allocation_tags_ids = nil, user_id=nil)
    opts = { 'type' => 'new', 'order' => 'desc', 'limit' => Rails.application.config.items_per_page.to_i,
      'display_mode' => 'list', 'page' => 1 }.merge(opts)
    type = (opts['type'] == 'history') ? '<' : '>'

    query = []
    query << "updated_at::timestamp(0) #{type} '#{opts["date"]}'::timestamp(0)" if opts.include?('date') && (!opts['date'].blank?)
    query << 'parent_id IS NULL' unless opts['display_mode'] == 'list'

    offset = (opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i

    posts_by_allocation_tags_ids(allocation_tags_ids, user_id, nil, { grandparent: false, query: query.join(' AND '),
                                                        order: "updated_at #{opts['order']}", limit: opts['limit'],
                                                        offset: offset })
  end

  def posts_not_limit(opts = {}, allocation_tags_ids = nil, user_id=nil)
    opts = { 'type' => 'new', 'order' => 'desc', 'limit' => Rails.application.config.items_per_page.to_i,
      'display_mode' => 'list', 'page' => 1, 'select' => 'DISTINCT discussion_posts.id, discussion_posts.*' }.merge(opts)
    type = (opts['type'] == 'history') ? '<' : '>'

    query = []
    query << "updated_at::timestamp(0) #{type} '#{opts["date"]}'::timestamp(0)" if opts.include?('date') && (!opts['date'].blank?)
    query << 'parent_id IS NULL' unless opts['display_mode'] == 'list'

    offset = (opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i

    posts_by_allocation_tags_ids(allocation_tags_ids, user_id, nil, { grandparent: false, query: query.join(' AND '),
                                                        order: "updated_at #{opts['order']}", select: 'DISTINCT discussion_posts.id, discussion_posts.*'})
  end

  def count_posts_after_and_before_period(period, allocation_tags_ids = nil, user_id=nil)
    [{ 'before' => count_posts_before_period(period, allocation_tags_ids),
       'after' => count_posts_after_period(period, allocation_tags_ids) }]
  end

  def count_posts_before_period(period, allocation_tags_ids = nil, user_id=nil)
    posts_by_allocation_tags_ids(allocation_tags_ids, user_id, nil, { query: "date_trunc('seconds', updated_at) < '#{period.first}'" }).count # trunc seconds - discard miliseconds
  end

  def count_posts_after_period(period, allocation_tags_ids = nil, user_id=nil)
    posts_by_allocation_tags_ids(allocation_tags_ids, user_id, nil, { query: "date_trunc('seconds', updated_at) > '#{period.last}'" }).count
  end

  # devolve a lista com todos os posts de uma discussion em ordem decrescente de updated_at, apenas o filho mais recente de cada post sera adiconado a lista
  def latest_posts(allocation_tags_ids = nil, user_id=nil)
    posts_by_allocation_tags_ids_to_api(allocation_tags_ids, user_id, nil, { select: 'DISTINCT ON (updated_at, parent_id) updated_at, parent_id, level' })
  end

  def posts_by_allocation_tags_ids(allocation_tags_ids = nil, user_id = nil, my_list=nil, opt = { grandparent: true, query: '', order: 'updated_at desc', limit: nil, offset: nil, select: 'DISTINCT discussion_posts.id, discussion_posts.*' })
    allocation_tags_ids = AllocationTag.where(id: allocation_tags_ids).map(&:related).flatten.compact.uniq
    posts_list = discussion_posts.includes(:files, :user, :profile).where(opt[:query]).order(opt[:order]).limit(opt[:limit]).offset(opt[:offset]).select(opt[:select])
    query_hash = {allocation_tags: { id: allocation_tags_ids }}
    query_hash.merge!({user_id: user_id}) unless my_list.blank?
    posts_list = posts_list.joins(academic_allocation: :allocation_tag).where(query_hash ) unless allocation_tags_ids.blank?
    posts_list = posts_list.where("(draft = ? ) OR (draft = ? AND user_id= ?)", false, true, user_id) if my_list.blank?

    (opt[:grandparent] ? posts_list.map(&:grandparent).uniq.compact : posts_list.to_a.compact.uniq)
  end

  def posts_by_allocation_tags_ids_to_api(allocation_tags_ids = nil, user_id = nil, my_list=nil, opt = { grandparent: true, query: '', order: 'updated_at desc', limit: nil, offset: nil, select: 'DISTINCT discussion_posts.id, discussion_posts.*' })
    allocation_tags_ids = AllocationTag.where(id: allocation_tags_ids).map(&:related).flatten.compact.uniq
    posts_list = discussion_posts.includes(:files).where(opt[:query]).order(opt[:order]).limit(opt[:limit]).offset(opt[:offset]).select(opt[:select])
    query_hash = {allocation_tags: { id: allocation_tags_ids }}
    query_hash.merge!({user_id: user_id}) unless my_list.blank?
    posts_list = posts_list.joins(academic_allocation: :allocation_tag).where(query_hash ) unless allocation_tags_ids.blank?
    posts_list = posts_list.where("(draft = ? ) OR (draft = ? AND user_id= ?)", false, true, user_id) if my_list.blank?

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
      .where(allocation_tags: { id: AllocationTag.find(allocation_tag_id).related }).select('discussions.id, discussions.name, COUNT(dp.id) AS posts_count, schedules.start_date AS start_date, schedules.end_date AS end_date')
      .group('discussions.id, discussions.name, start_date, end_date').order('start_date').uniq
  end

  def self.all_by_allocation_tags(allocation_tag_id)
    joins(:schedule, academic_allocations: :allocation_tag)
    .joins('LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id')
    .where(allocation_tags: { id: AllocationTag.find(allocation_tag_id).related })
    .select('discussions.*, academic_allocations.id AS ac_id, COUNT(discussion_posts.id) AS posts_count, schedules.start_date AS start_date, schedules.end_date AS end_date')
    .group('discussions.id, schedules.start_date, schedules.end_date, name, academic_allocations.id')
    .order('start_date, end_date, name')
  end

  def self.update_previous(academic_allocation_id, user_id, academic_allocation_user_id)
    Post.where(academic_allocation_id: academic_allocation_id, user_id: user_id).update_all academic_allocation_user_id: academic_allocation_user_id
  end

  def self.verify_previous(acu_id)
    Post.where(academic_allocation_user_id: acu_id, draft: false).any?
  end

end

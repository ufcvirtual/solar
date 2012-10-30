class Discussion < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :schedule

  has_many :discussion_posts, :class_name => "Post", :foreign_key => "discussion_id"

  validates :name, :description, :presence => true
  validate :unique_name

  before_destroy :can_destroy?

  ##
  # Verifica se pode deletar o fórum
  # Permite apenas se ainda não tiver iniciado ou estiver concluído e não tiver nenhuma participação
  ##
  def can_destroy?
    if (schedule.start_date < Date.today) or (closed? and (not discussion_posts.empty?))
      errors.add(:base, I18n.t(:cant_delete, :scope => [:discussion, :errors])) 
      return false
    else
      return true
    end
  end

  ##
  # Validação que verifica se o nome do fórum já existe naquela allocation_tag
  ##
  def unique_name
    discussions_with_same_name = Discussion.find_all_by_allocation_tag_id_and_name(allocation_tag_id, name)
    errors.add(:base, I18n.t(:existing_name, :scope => [:discussion, :errors])) if (@new_record == true or name_changed?) and discussions_with_same_name.size > 0
  end

  def closed?
    self.schedule.end_date < Date.today
  end

  def extra_time?(user_id)
    (self.allocation_tag.is_user_class_responsible?(user_id) and self.closed?) ?
      ((self.schedule.end_date.to_datetime + Discussion_Responsible_Extra_Time) >= Date.today) : false
  end

  def user_can_see?(user_id)
    allocation_tags = AllocationTag.find_related_ids(self.allocation_tag_id).join(',')
    allocations     = Allocation.where("allocation_tag_id IN (#{allocation_tags}) AND status = #{Allocation_Activated} AND user_id = #{user_id}")

    (allocations.length > 0) and (self.schedule.start_date <= Date.today)
  end

  def user_can_interact?(user_id)
    return false unless user_can_see?(user_id)
    return (!self.closed? or extra_time?(user_id))
  end

  def posts(opts = {})
    opts = { "type" => 'news', "order" => 'desc', "limit" => Rails.application.config.items_per_page.to_i,
      "display_mode" => 'list', "page" => 1 }.merge(opts)
    type = (opts["type"] == 'news') ? '>' : '<'
    innder_order = (opts["type"] == 'news') ? 'asc' : 'desc'

    where = ["t2.id = #{self.id}"]
    where << "t1.updated_at::timestamp(0) #{type} '#{opts["date"].to_time}'::timestamp(0)" if opts.include?('date')
    where << "parent_id IS NULL" unless opts["display_mode"] == 'list'

    query = <<SQL
      WITH cte_posts AS (
        SELECT t1.id,
               t1.parent_id,
               t1.profile_id,
               t1.discussion_id,
               t3.id            AS user_id,
               t3.nick          AS user_nick,
               t1.level,
               t1.content,
               t1.updated_at::timestamp(0)
          FROM discussion_posts AS t1
          JOIN discussions      AS t2 ON t2.id = t1.discussion_id
          JOIN users            AS t3 ON t3.id = t1.user_id
         WHERE #{where.join(' AND ')}
         ORDER BY updated_at #{innder_order}
         LIMIT #{opts['limit']} OFFSET #{(opts['page'].to_i * opts['limit'].to_i) - opts['limit'].to_i}
      )
      --
      SELECT *
        FROM cte_posts
       ORDER BY updated_at #{opts['order']}, id #{opts['order']}
SQL

    Post.find_by_sql(query)
  end

  def discussion_posts_count(plain_list = true)
    return self.discussion_posts.count if plain_list
    return self.discussion_posts.where(:parent_id => nil).count
  end

  def count_posts_after_and_before_period(period)
    [{"before" => self.discussion_posts.where("updated_at::timestamp(0) < '#{period.first}'").count,
      "after" => self.discussion_posts.where("updated_at::timestamp(0) > '#{period.last}'").count}]
  end

  def self.all_by_allocations_and_student_id(allocation_tags, student_id)
    query = <<SQL
      WITH cte_discussions AS (
          SELECT t2.id            AS allocation_tag_id,
                 t1.id            AS discussion_id,
                 t1.name          AS discussion_name
            FROM discussions      AS t1
            JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
           WHERE t2.id IN (#{allocation_tags.join(',')})
             AND t2.group_id IS NOT NULL
      )
      -- todos os posts de cada forum
      SELECT t2.discussion_id,
             t2.discussion_name AS name,
             COUNT(t1.id) AS qtd
        FROM discussion_posts AS t1
  RIGHT JOIN cte_discussions  AS t2 ON t2.discussion_id = t1.discussion_id AND t1.user_id = #{student_id}
       GROUP BY t2.discussion_id, t2.discussion_name
SQL

    ActiveRecord::Base.connection.select_all(query)
  end

  def self.all_by_allocation_tags(allocation_tags)
    query = <<SQL
      SELECT t1.id,
             t1.name,
             t1.description,
             t1.schedule_id,
             t1.allocation_tag_id,
             CASE WHEN t3.start_date >= now() THEN 0 -- nao iniciado
                  WHEN t3.end_date >= now() THEN 1 -- aberto
                  WHEN t3.end_date < now() THEN 2 -- fechado
                  ELSE 0
             END AS status,
             max(t4.updated_at::timestamp(0)) AS last_post_date,
             t3.start_date,
             t3.end_date
        FROM discussions      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN schedules        AS t3 ON t1.schedule_id = t3.id
   LEFT JOIN discussion_posts AS t4 ON t4.discussion_id = t1.id
       WHERE t2.id IN (#{allocation_tags.join(',')})
       GROUP BY t1.id, t1.name, t1.description, t1.schedule_id, t1.allocation_tag_id, t3.start_date, t3.end_date
       ORDER BY t3.start_date, t3.end_date, t1.name
SQL

    Discussion.find_by_sql(query)
  end

end

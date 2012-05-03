class Discussion < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :schedule

  has_many :discussion_posts






  #############

  def closed?
    self.schedule.end_date < Date.today
  end

  def extra_time?(user_id)
    (self.allocation_tag.is_user_class_responsible?(user_id) and self.closed?) ? ((self.schedule.end_date + Discussion_Responsible_Extra_Time) >= Date.today) : false
  end

  def user_can_see?(user_id)
    allocation_tags = AllocationTag.find_related_ids(self.allocation_tag_id).join(',')
    allocations = Allocation.where("allocation_tag_id IN (#{allocation_tags}) AND status = #{Allocation_Activated} AND user_id = #{user_id}")

    (allocations.length > 0)
  end

  def user_can_interact?(user_id)
    return false unless user_can_see?(user_id)
    return (!self.closed? or extra_time?(user_id))
  end

  def posts(opts = {})
    opts = { "type" => 'news', "order" => 'desc', "limit" => 20, "display_mode" => 'list' }.merge(opts)
    type = (opts["type"] == 'news') ? '>' : '<'

    query = <<SQL
        SELECT t1.id,
               t1.level,
               t1.parent_id,
               t1.profile_id,
               t1.discussion_id,
               t1.user_id,
               t1.content,
               t1.updated_at
          FROM discussion_posts AS t1
          JOIN discussions      AS t2 ON t2.id = t1.discussion_id
         WHERE t2.id = #{self.id}
           AND t1.updated_at::timestamp(0) #{type} '#{opts["date"].to_time}'::timestamp(0)
        #{"AND parent_id IS NULL" unless opts["display_mode"] == 'list'}
         ORDER BY t1.updated_at #{opts["order"]}, t1.id #{opts["order"]}
         LIMIT #{opts["limit"]}
SQL

    DiscussionPost.find_by_sql query
  end

  def count_posts_after_and_before_period(period)
    query = <<SQL
      WITH cte_before AS (
        SELECT count(DISTINCT t1.id) AS before
          FROM discussion_posts AS t1
          JOIN discussions      AS t2 ON t2.id = t1.discussion_id
         WHERE t2.id = #{self.id}
           AND updated_at::timestamp(0) < '#{period.first.to_time}'::timestamp(0)
      ),
      cte_after AS (
        SELECT count(DISTINCT t1.id) AS after
          FROM discussion_posts AS t1
          JOIN discussions      AS t2 ON t2.id = t1.discussion_id
         WHERE t2.id = #{self.id}
           AND updated_at::timestamp(0) > '#{period.last.to_time}'::timestamp(0)
      )
      --
      SELECT (SELECT before FROM cte_before) AS before, (SELECT after FROM cte_after) AS after
SQL

    ActiveRecord::Base.connection.select_all query
  end










  ##
  # Todas as discussoes por estudante no grupo
  ##
  def self.all_by_allocations_and_student_id(allocations, student_id)
    query = <<SQL
      WITH cte_discussions AS (
          SELECT t2.id            AS allocation_tag_id,
                 t1.id            AS discussion_id,
                 t1.name          AS discussion_name
            FROM discussions      AS t1
            JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
           WHERE t2.id IN (#{allocations.join(',')})
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

    ActiveRecord::Base.connection.select_all query
  end

  ##
  # Recupera discussions com informacoes de que o mesmo foi finalizado
  ##
  def self.all_by_allocations(allocations)
    query = <<SQL
      SELECT t1.id, t1.name, t1.description, t1.schedule_id, t1.allocation_tag_id, t3.start_date, t3.end_date,
        CASE WHEN t3.end_date < now()::date THEN true
             ELSE false
         END AS closed
        FROM discussions      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN schedules        AS t3 ON t1.schedule_id = t3.id
       WHERE t2.id IN (#{allocations})
SQL

    Discussion.find_by_sql(query)
  end

  def discussion_posts_count(plain_list = true)
    return self.discussion_posts.count() if plain_list
    self.discussion_posts.where(:parent_id => nil).count
  end
  
  def discussion_posts_page(plain_list = true, page = 1)
    return self.discussion_posts.paginate(:per_page => Rails.application.config.items_per_page, :page => page) if plain_list
    self.discussion_posts.where(:parent_id => nil).paginate(:per_page => Rails.application.config.items_per_page, :page => page)
  end

end

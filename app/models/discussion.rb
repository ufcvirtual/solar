class Discussion < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :schedules

  has_many :discussion_posts

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

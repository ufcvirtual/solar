class Discussion < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :schedules
  
  has_many :discussion_posts

  # Todas os foruns do grupo por usuario
  def self.all_by_group_and_student_id(group_id, student_id)
    discussions = ActiveRecord::Base.connection.select_all <<SQL
      WITH cte_discussions AS (
          SELECT t2.id            AS allocation_tag_id,
                 t1.id            AS discussion_id,
                 t1.name          AS discussion_name
            FROM discussions      AS t1
            JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
           WHERE t2.group_id = #{group_id}
      )
      -- todos os posts de cada forum
      SELECT t2.discussion_id,
             t2.discussion_name AS name,
             COUNT(t1.id) AS qtd
        FROM discussion_posts AS t1
        JOIN cte_discussions  AS t2 ON t2.discussion_id = t1.discussion_id
       WHERE user_id = #{student_id}
       GROUP BY t2.discussion_id, t2.discussion_name
SQL

    return (discussions.nil?) ? [] : discussions
  end

end

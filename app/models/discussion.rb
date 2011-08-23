class Discussion < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :schedules
  
  has_many :discussion_posts

  # Todas os foruns do grupo por usuario
  def self.all_by_group_id_and_student_id(group_id, student_id)
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
  RIGHT JOIN cte_discussions  AS t2 ON t2.discussion_id = t1.discussion_id AND t1.user_id = #{student_id}
       GROUP BY t2.discussion_id, t2.discussion_name
SQL

    return (discussions.nil?) ? [] : discussions
  end

  def self.all_by_offer_id_and_group_id(offer_id, group_id)

    group_id = -1 if group_id.nil?
    offer_id = -1 if offer_id.nil?

    # retorna os fóruns da turma
    # at.id as id, at.offer_id as offerid,l.allocation_tag_id as alloctagid,l.type_lesson, privacy,description,
    query = "SELECT *
              FROM
                (SELECT d.name, d.id, d.start, d.end, d.description
                 FROM discussions d
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN groups g on g.id = t.group_id
                 WHERE g.id = #{group_id}

                 UNION ALL

                 SELECT d.name, d.id, d.start, d.end, d.description
                 FROM discussions d
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN offers o on o.id = t.offer_id
                 WHERE o.id = #{offer_id}
                ) as available_discussions
              ORDER BY start;"

    return Discussion.find_by_sql(query)

  end

end

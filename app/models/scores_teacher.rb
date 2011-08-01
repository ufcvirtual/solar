class ScoresTeacher < ActiveRecord::Base

  set_table_name "assignment_comments"

  def self.list_students_by_group_id(group_id, page = 1)
    paginate_by_sql "
    WITH cte_private_files AS (
       SELECT t1.id         AS user_id,
              COUNT(t4.id)  AS cnt_private_files
         FROM users             AS t1
    LEFT JOIN send_assignments  AS t2 ON t2.user_id = t1.id
    LEFT JOIN assignments       AS t3 ON t3.id = t2.assignment_id
    LEFT JOIN assignment_files  AS t4 ON t4.send_assignment_id = t2.id
        GROUP BY t1.id
    )
    --
      SELECT DISTINCT t1.id,
             t1.name,
             COUNT(t7.id) AS cnt_public_files,
             t8.cnt_private_files
        FROM users              AS t1
        JOIN allocations        AS t2 ON t2.user_id = t1.id
        JOIN profiles           AS t3 ON t3.id = t2.profile_id
        JOIN allocation_tags    AS t4 ON t4.id = t2.allocation_tag_id
        JOIN groups             AS t5 ON t5.id = t4.group_id
        JOIN cte_private_files  AS t8 ON t8.user_id = t1.id
   LEFT JOIN public_files       AS t7 ON t7.allocation_tag_id = t4.id AND t7.user_id = t1.id
       WHERE t3.student = TRUE
         AND t5.id = #{group_id}
       GROUP BY t1.id, t1.name, t8.cnt_private_files
       ORDER BY t1.name, t1.id",
      {:per_page => Rails.application.config.items_per_page, :page => page}

  end

  def self.number_of_students_by_group_id(group_id)
    cnt = ActiveRecord::Base.connection.select_all <<SQL
  SELECT COUNT(DISTINCT t1.id)::int AS cnt
     FROM users             AS t1
     JOIN allocations       AS t2 ON t2.user_id = t1.id
     JOIN allocation_tags   AS t3 ON t3.id = t2.allocation_tag_id
     JOIN profiles          AS t4 ON t4.id = t2.profile_id
    WHERE t3.group_id = #{group_id}
      AND t4.student = TRUE;
SQL

    return (cnt.nil?) ? 0 : cnt.first["cnt"].to_i
  end

end

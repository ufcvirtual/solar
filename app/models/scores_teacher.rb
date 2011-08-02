class ScoresTeacher < ActiveRecord::Base

  set_table_name "assignment_comments"

  def self.list_students_by_group_id(group_id, page = 1)

    sql = <<SQL
    WITH cte_assignments AS (
      SELECT t2.user_id,
             translate(array_agg(
             CASE
                WHEN t2.grade IS NOT NULL THEN t2.grade::text
                WHEN t3.id    IS NOT NULL THEN 'TE'
                WHEN t3.id    IS NULL     THEN 'TN'
             END
             )::text, '{}', '') AS assignment_grades,
             translate(array_agg(t2.assignment_id)::text,'{}','') AS assignment_ids
        FROM assignments      AS t1
        JOIN allocation_tags  AS t4 ON t4.id = t1.allocation_tag_id
   LEFT JOIN send_assignments AS t2 ON t2.assignment_id = t1.id
   LEFT JOIN assignment_files AS t3 ON t3.send_assignment_id = t2.id
       WHERE t4.group_id = 3
       GROUP BY t2.user_id
       ORDER BY t2.user_id
    )
    --
      SELECT DISTINCT t1.id,
             t1.name,
             COUNT(t7.id) AS cnt_public_files,
             COALESCE(t8.assignment_grades, 'TN,TN') AS assignment_grades,
             COALESCE(t8.assignment_ids, '2,3')      AS assignment_ids
        FROM users              AS t1
        JOIN allocations        AS t2 ON t2.user_id = t1.id
        JOIN profiles           AS t3 ON t3.id = t2.profile_id
        JOIN allocation_tags    AS t4 ON t4.id = t2.allocation_tag_id
        JOIN groups             AS t5 ON t5.id = t4.group_id
   LEFT JOIN cte_assignments AS t8 ON t8.user_id = t1.id
   LEFT JOIN public_files       AS t7 ON t7.allocation_tag_id = t4.id AND t7.user_id = t1.id
       WHERE t3.student = TRUE
         AND t5.id = #{group_id}
       GROUP BY t1.id, t1.name, t8.assignment_grades, t8.assignment_ids
       ORDER BY t1.name, t1.id
SQL

    paginate_by_sql sql, {:per_page => Rails.application.config.items_per_page, :page => page}

  end

  # numero de estudantes por group
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

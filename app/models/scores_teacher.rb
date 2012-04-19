class ScoresTeacher < ActiveRecord::Base

  set_table_name "assignment_comments"

  # Listagem dos alunos por turma
  def self.list_students_by_curriculum_unit_id_and_group_id(curriculum_unit_id, group_id, page = 1)
    query = <<SQL
    WITH cte_assignments AS (
      SELECT t2.id              AS allocation_tag_id,
             t1.id              AS assignment_id,
             t1.name            AS assignment_name,
             t3.start_date,
             t3.end_date
        FROM assignments        AS t1
        JOIN allocation_tags    AS t2 ON t2.id = t1.allocation_tag_id
        JOIN schedules          AS t3 ON t3.id = t1.schedule_id
       WHERE t2.group_id = #{group_id}
       ORDER BY t3.start_date
    ),
    -- alunos da turma
    cte_students AS (
      SELECT t1.id              AS student_id,
             t1.name            AS student_name,
             t2.id              AS allocation_id,
             t4.id              AS allocation_tag_id
        FROM users              AS t1
        JOIN allocations        AS t2 ON t2.user_id = t1.id
        JOIN profiles           AS t3 ON t3.id = t2.profile_id
        JOIN allocation_tags    AS t4 ON t4.id = t2.allocation_tag_id
       WHERE cast( t3.types & '#{Profile_Type_Student}' as boolean)
         AND t4.group_id = #{group_id}
         AND t2.status = #{Allocation_Activated}
       ORDER BY t1.id
    ),
    -- contador de arquivos publicos por usuario
    cte_public_files AS (
        SELECT t2.student_id,
               COUNT(t1.id)     AS cnt_public_files
          FROM public_files     AS t1
    RIGHT JOIN cte_students     AS t2 ON t2.student_id = t1.user_id AND t2.allocation_tag_id = t1.allocation_tag_id
         GROUP BY t2.student_id
         ORDER BY t2.student_id
    ),
    -- notas dos alunos
    cte_grades AS (
        SELECT DISTINCT t2.student_id,
               t2.student_name,
               t1.assignment_id,
               t1.start_date,
               CASE
                  WHEN t1.assignment_id IS NULL THEN NULL
                  WHEN t3.grade IS NOT NULL THEN t3.grade::text -- nota do aluno
                  WHEN t4.id    IS NOT NULL THEN 'as' -- trabalho enviado e nao corrigido
                  WHEN t4.id    IS NULL     THEN 'an' -- trabalho nao enviado
               END AS grade,
               t3.id                AS send_assignment_id
          FROM cte_assignments      AS t1
    RIGHT JOIN cte_students         AS t2 ON t2.allocation_tag_id = t1.allocation_tag_id
     LEFT JOIN send_assignments     AS t3 ON t3.assignment_id = t1.assignment_id AND t3.user_id = t2.student_id
     LEFT JOIN assignment_files     AS t4 ON t4.send_assignment_id = t3.id
         ORDER BY t2.student_id, t1.start_date
    ),
    -- acessos de cada aluno no curso
    cte_access AS (
        SELECT t1.student_id,
               count(t2.id) AS cnt_access
          FROM cte_students AS t1
     LEFT JOIN logs AS t2 ON t2.user_id = t1.student_id AND log_type = 3 AND curriculum_unit_id = #{curriculum_unit_id}
         GROUP BY t1.student_id
         )
    --
    SELECT t1.student_id,
           initcap(t1.student_name)                                       AS student_name,
           translate(array_agg(t1.grade)::text,'{}NULL','')               AS grades,
           translate(array_agg(t1.assignment_id)::text,'{}NULL','')       AS assignment_ids,
           translate(array_agg(t1.send_assignment_id)::text,'{}NULL','')  AS send_assignment_ids,
           t2.cnt_public_files,
           t3.cnt_access
      FROM cte_grades                   AS t1
      JOIN cte_public_files             AS t2 ON t2.student_id = t1.student_id
      JOIN cte_access                   AS t3 ON t3.student_id = t1.student_id
     GROUP BY t1.student_id, t1.student_name, t2.cnt_public_files, t3.cnt_access
     ORDER BY t1.student_name
SQL

    paginate_by_sql query, {:per_page => Rails.application.config.items_per_page, :page => page}
  end

  # Numero de estudantes por group
  def self.number_of_students_by_group_id(group_id)
    query = <<SQL
  SELECT COUNT(DISTINCT t1.id)::int AS cnt
     FROM users             AS t1
     JOIN allocations       AS t2 ON t2.user_id = t1.id
     JOIN allocation_tags   AS t3 ON t3.id = t2.allocation_tag_id
     JOIN profiles          AS t4 ON t4.id = t2.profile_id
    WHERE t3.group_id = #{group_id}
      AND cast(t4.types & '#{Profile_Type_Student}' as boolean)
      AND t2.status = #{Allocation_Activated};
SQL

    cnt = ActiveRecord::Base.connection.select_all query

    return (cnt.nil?) ? 0 : cnt.first["cnt"].to_i
  end

end

class ScoresTeacher < ActiveRecord::Base

  set_table_name "assignment_comments"

  # Listagem dos alunos por turma
  def self.list_students_by_group_id(group_id, page = 1)

    sql = <<SQL
    -- todas as atividades do grupo
    WITH cte_assignments AS (
      SELECT t2.id              AS allocation_tag_id,
             t1.id              AS assignment_id,
             t1.name            AS assignment_name,
             t1.start_date,
             t1.end_date
        FROM assignments        AS t1
        JOIN allocation_tags    AS t2 ON t2.id = t1.allocation_tag_id
       WHERE t2.group_id = #{group_id}
       ORDER BY t1.start_date
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
       WHERE t3.student = TRUE
         AND t4.group_id = #{group_id}
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
                  WHEN t3.grade IS NOT NULL THEN t3.grade::text -- nota do aluno
                  WHEN t4.id    IS NOT NULL THEN 'as' -- trabalho enviado e nao corrigido
                  WHEN t4.id    IS NULL     THEN 'an' -- trabalho nao enviado
               END AS grade,
               t3.id                AS send_assignment_id
          FROM cte_assignments      AS t1
          JOIN cte_students         AS t2 ON t2.allocation_tag_id = t1.allocation_tag_id
     LEFT JOIN send_assignments     AS t3 ON t3.assignment_id = t1.assignment_id AND t3.user_id = t2.student_id
     LEFT JOIN assignment_files     AS t4 ON t4.send_assignment_id = t3.id
         ORDER BY t2.student_id, t1.start_date
    )
    --
    SELECT t1.student_id,
           t1.student_name,
           translate(array_agg(t1.grade)::text,'{}','')              AS grades,
           translate(array_agg(t1.assignment_id)::text,'{}','')      AS assignment_ids,
           translate(array_agg(t1.send_assignment_id)::text,'{}NULL','') AS send_assignment_ids,
           t2.cnt_public_files
      FROM cte_grades                   AS t1
      JOIN cte_public_files             AS t2 ON t2.student_id = t1.student_id
     GROUP BY t1.student_id, t1.student_name, t2.cnt_public_files
     ORDER BY t1.student_name
SQL

    paginate_by_sql sql, {:per_page => Rails.application.config.items_per_page, :page => page}

  end

  # Numero de estudantes por group
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

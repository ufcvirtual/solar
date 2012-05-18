class PortfolioTeacher < ActiveRecord::Base

  self.table_name = "assignment_comments"

  ##
  # Lista de alunos presentes nas turmas
  ##
  def self.list_students_by_allocations(allocations)
    query = <<SQL
      SELECT DISTINCT t3.id,
             initcap(t3.name) AS name
        FROM allocations      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN users            AS t3 ON t3.id = t1.user_id
        JOIN profiles         AS t4 ON t4.id = t1.profile_id
       WHERE t2.id IN (#{allocations})
         AND cast( t4.types & '#{Profile_Type_Student}' as boolean) 
         AND t1.status = #{Allocation_Activated}
         AND t2.group_id IS NOT NULL
       ORDER BY name
SQL

    ActiveRecord::Base.connection.select_all query
  end

  ##
  # Atividades do aluno na turma
  ##
  def self.list_assignments_by_allocations_and_student_id(allocations, student_id)
    query = <<SQL
      SELECT DISTINCT
             t1.name AS assignments_name,
             t1.id AS assignment_id,
             t5.start_date,
             t5.end_date,
             t3.grade,
             t3.id AS send_assignment_id,
             CASE
                WHEN t5.start_date > now() THEN 'not_started'
                WHEN t3.grade IS NOT NULL AND COUNT(t4.id) > 0 THEN 'corrected'
                WHEN COUNT(t4.id) > 0 THEN 'sent'
                WHEN COUNT(t4.id) = 0 AND t5.end_date > now() THEN 'pending'
                WHEN COUNT(t4.id) = 0 AND t5.end_date < now() THEN 'not_sent'
                ELSE '-'
             END AS situation
        FROM assignments      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
   LEFT JOIN send_assignments AS t3 ON t3.assignment_id = t1.id AND t3.user_id = #{student_id}
   LEFT JOIN assignment_files AS t4 ON t4.send_assignment_id = t3.id
   LEFT JOIN schedules        AS t5 ON t5.id = t1.schedule_id
       WHERE t2.id IN (#{allocations.join(',')})
         AND t2.group_id IS NOT NULL
       GROUP BY t1.id, t1.name, t5.start_date, t5.end_date, t3.id, t3.grade
       ORDER BY t5.end_date;
SQL

    ActiveRecord::Base.connection.select_all query
  end

end

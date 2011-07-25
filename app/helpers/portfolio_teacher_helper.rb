module PortfolioTeacherHelper

  # lista com as atividades do aluno dentro na turma
  def list_assignments_by_group_and_student(groups_id, students_id)
    assignments = ActiveRecord::Base.connection.select_all <<SQL
      SELECT DISTINCT
             t1.name AS assignments_name,
             t1.id AS assignment_id,
             t1.start_date,
             t1.end_date,
             t2.grade,
             t2.id AS send_assignment_id,
             CASE
                WHEN t2.grade IS NOT NULL THEN 'corrected'
                WHEN COUNT(t3.id) > 0 THEN 'sent'
                WHEN COUNT(t3.id) = 0 AND t1.end_date > now() THEN 'not_sent'
                ELSE '-'
             END AS situation
        FROM assignments      AS t1
        JOIN allocation_tags  AS t4 ON t4.id = t1.allocation_tag_id
   LEFT JOIN send_assignments AS t2 ON t2.assignment_id = t1.id AND t2.user_id = #{students_id}
   LEFT JOIN assignment_files AS t3 ON t3.send_assignment_id = t2.id
       WHERE t4.group_id = #{groups_id}
       GROUP BY t1.id, t1.name, t1.start_date, t1.end_date, t2.id, t2.grade
       ORDER BY t1.end_date;
SQL
    return (assignments.nil?) ? [] : assignments
  end

end

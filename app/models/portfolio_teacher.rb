class PortfolioTeacher < ActiveRecord::Base

  set_table_name "assignment_comments"

  # lista de alunos por turma
  def self.list_students_by_group_id(group_id)
    User.joins(:allocations => [{:allocation_tag => [:group, :assignments]}, :profile]).
      select("DISTINCT users.id, users.name").
      where("profiles.student = TRUE AND groups.id = ?", group_id).
      order("users.name")
  end

  # lista com as atividades do aluno dentro na turma
  def self.list_assignments_by_group_and_student_id(group_id, student_id)
    assignments = ActiveRecord::Base.connection.select_all <<SQL
      SELECT DISTINCT
             t1.name AS assignments_name,
             t1.id AS assignment_id,
             t5.start_date,
             t5.end_date,
             t3.grade,
             t3.id AS send_assignment_id,
             CASE
                WHEN t5.start_date > now() THEN 'not_started'
                WHEN t3.grade IS NOT NULL THEN 'corrected'
                WHEN COUNT(t4.id) > 0 THEN 'sent'
                WHEN COUNT(t4.id) = 0 AND t5.end_date > now() THEN 'not_sent'
                ELSE '-'
             END AS situation
        FROM assignments      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
   LEFT JOIN send_assignments AS t3 ON t3.assignment_id = t1.id AND t3.user_id = #{student_id}
   LEFT JOIN assignment_files AS t4 ON t4.send_assignment_id = t3.id
   LEFT JOIN schedules        AS t5 ON t5.id = t1.schedule_id
       WHERE t2.group_id = #{group_id}
       GROUP BY t1.id, t1.name, t5.start_date, t5.end_date, t3.id, t3.grade
       ORDER BY t5.end_date;
SQL

    return (assignments.nil?) ? [] : assignments
  end

end

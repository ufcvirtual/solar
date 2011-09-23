class Portfolio < ActiveRecord::Base

  set_table_name "assignments"

  belongs_to :schedule

  # atividades individuais
  def self.individual_activities(group_id, students_id)

    ia = ActiveRecord::Base.connection.select_all <<SQL
    SELECT DISTINCT
           t1.id,
           t1.name,
           t1.enunciation,
           t7.start_date,
           t7.end_date,
           t2.grade,
           CASE WHEN t3.comment IS NOT NULL THEN 1 ELSE 0 END AS comments,
           CASE
            WHEN t7.start_date > now() THEN 'not_started'
            WHEN t2.grade IS NOT NULL THEN 'corrected'
            WHEN COUNT(t6.id) > 0 THEN 'sent'
            WHEN COUNT(t6.id) = 0 AND t7.end_date > now() THEN 'send'
            ELSE '-'
           END AS correction
      FROM assignments         AS t1
      JOIN allocation_tags     AS t4 ON t4.id = t1.allocation_tag_id
      JOIN allocations         AS t5 ON t5.allocation_tag_id = t4.id
 LEFT JOIN send_assignments    AS t2 ON t2.assignment_id = t1.id AND t2.user_id = #{students_id}
 LEFT JOIN assignment_comments AS t3 ON t3.send_assignment_id = t2.id
 LEFT JOIN assignment_files    AS t6 ON t6.send_assignment_id = t2.id
 LEFT JOIN schedules           AS t7 ON t7.id = t1.schedule_id
     WHERE t4.group_id = #{group_id}
       AND t5.user_id = #{students_id}
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t7.start_date, t7.end_date, t2.grade, t3.comment
  ORDER BY t7.end_date, t7.start_date DESC;
SQL

    return (ia.nil?) ? [] : ia

  end

  # arquivos da area publica
  def self.public_area(group_id, user_id)

    pa = ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.attachment_file_name,
           t1.attachment_content_type,
           t1.attachment_file_size,
           t1.attachment_updated_at
      FROM public_files AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN users AS t3 ON t3.id = t1.user_id
     WHERE t3.id = #{user_id}
       AND t2.group_id = #{group_id};
SQL

    return (pa.nil?) ? [] : pa

  end

  # informacoes sobre a atividade do aluno
  def self.assignments_student(student_id, assignment_id)
    SendAssignment.
      joins("LEFT JOIN assignment_files ON assignment_files.send_assignment_id = send_assignments.id").
      where(["send_assignments.assignment_id = ? AND send_assignments.user_id = ?", assignment_id, student_id])
  end

end

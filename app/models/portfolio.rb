class Portfolio < ActiveRecord::Base

  set_table_name "assignments"

  belongs_to :schedule

  def self.student_activities(group_id, students_id, type_assignment)

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
            WHEN t2.grade IS NOT NULL AND COUNT(t6.id) > 0 THEN 'corrected'
            WHEN COUNT(t6.id) > 0 THEN 'sent'
            WHEN COUNT(t6.id) = 0 AND t7.end_date > now() THEN 'send'
            WHEN COUNT(t6.id) = 0 AND t7.end_date < now() THEN 'not_sent'
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
       AND t1.type_assignment = #{type_assignment}
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t7.start_date, t7.end_date, t2.grade, t3.comment
  ORDER BY t7.end_date, t7.start_date DESC;
SQL

    return (ia.nil?) ? [] : ia

  end

  ##
  # Participantes do grupo do aluno e da atividade em questão
  ##
  def self.find_group_participants(activity, user_id)
    # acha o grupo de determinado aluno para determinado trabalho
    group_assignment = ActiveRecord::Base.connection.select_all <<SQL
    SELECT  t1.group_assignment_id
      FROM group_participants AS t1
      JOIN group_assignments AS t2 ON t1.group_assignment_id = t2.id AND t2.assignment_id = #{activity}
    WHERE #{user_id} = t1.user_id;
SQL

  # se o aluno não estiver em nenhum grupo, retorna nulo
  if group_assignment.empty?
    return nil
  else
  # caso contrário, pesquisa os participantes do grupo encontrado
    group_participants = GroupParticipant.find_all_by_group_assignment_id(group_assignment[0]["group_assignment_id"].to_i)
    return group_participants
  end

  end

  ##
  # Arquivos da area publica
  ##
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

  ##
  # Informacoes sobre a atividade do aluno
  ##
  def self.assignments_student(student_id, assignment_id)
    SendAssignment.
      joins("LEFT JOIN assignment_files ON assignment_files.send_assignment_id = send_assignments.id").
      where(["send_assignments.assignment_id = ? AND send_assignments.user_id = ?", assignment_id, student_id])
  end

end

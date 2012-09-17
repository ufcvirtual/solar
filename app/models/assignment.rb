class Assignment < ActiveRecord::Base

  has_many :allocations, :through => :allocation_tag
  has_one :group, :through => :allocation_tag
  belongs_to :allocation_tag
  belongs_to :schedule
  has_many :assignment_enunciation_files
  has_many :send_assignments
  has_many :group_assignments


  ##
  # Recupera status da atividade
  ##
  def self.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student_id)
    status_assignment = ActiveRecord::Base.connection.select_all <<SQL
    SELECT
           CASE
            WHEN t4.start_date > now()                    THEN 'not_started'
            WHEN t2.grade IS NOT NULL                     THEN 'corrected'
            WHEN COUNT(t3.id) > 0                         THEN 'sent'
            WHEN COUNT(t3.id) = 0 AND t4.end_date > now() THEN 'send'
            WHEN COUNT(t3.id) = 0 AND t4.end_date < now() THEN 'not_sent'
            ELSE '-'
           END AS assignment_status
      FROM assignments        AS t1
 LEFT JOIN group_participants AS t5 ON t5.user_id = #{student_id}
 LEFT JOIN send_assignments   AS t2 ON t2.assignment_id = t1.id AND (t2.group_assignment_id = t5.group_assignment_id OR t2.user_id = #{student_id})
 LEFT JOIN assignment_files   AS t3 ON t3.send_assignment_id = t2.id
 LEFT JOIN schedules          AS t4 ON t4.id = t1.schedule_id
     WHERE t1.id = #{assignment_id}
     GROUP BY t1.id, t2.id, t4.start_date, t4.end_date, t2.grade;
SQL

    return (status_assignment.first.nil?) ? '-' : status_assignment.first['assignment_status']
  end

  def closed?
    self.schedule.end_date < Date.today
  end

  def extra_time?(user_id)
    (self.allocation_tag.is_user_class_responsible?(user_id) and self.closed?) ?
      ((self.schedule.end_date.to_datetime + Assignment_Responsible_Extra_Time) >= Date.today) : false
  end

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
  # Recupera as atividades de determinado tipo de uma turma e informações da situação de determinado aluno nela
  ##
  def self.student_assignments_info(class_id, student_id, type_assignment)

    assignments = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = #{class_id} AND assignments.type_assignment = #{type_assignment}"],
     :select => ["assignments.id", "schedule_id", "name", "enunciation", "type_assignment"]) #atividades da turma do tipo escolhido
  
    assignments_grades, groups_ids, has_comments, situation = [], [], [], [] # informações da situação do aluno

    assignments.each_with_index do |assignment, idx|

      student_group = (assignment.type_assignment == Group_Activity) ? (GroupAssignment.first(:include => [:group_participants], :conditions => ["group_participants.user_id = #{student_id} 
        AND group_assignments.assignment_id = #{assignment.id}"])) : nil #grupo do aluno
      user_id = (assignment.type_assignment == Group_Activity) ? nil : student_id #id do aluno
      groups_ids[idx] = (student_group.nil? ? nil : student_group.id) #se aluno estiver em grupo, recupera id
      send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(assignment.id, user_id, groups_ids[idx])

      assignments_grades[idx] = send_assignment.nil? ? nil : send_assignment.grade #se tiver send_assignment, tenta pegar nota
      has_comments[idx] = send_assignment.nil? ? nil :  !(send_assignment.assignment_comments.empty? and send_assignment.comment.blank?) #verifica se há comentários para o aluno

      #situação do aluno na atividade
      if assignment.schedule.start_date > Date.current()
        situation[idx] = "not_started"  
      elsif (not assignments_grades[idx].nil?)
        situation[idx] = "corrected"
      elsif assignment.type_assignment == Group_Activity and groups_ids[idx].nil?
        situation[idx] = "without_group"
      elsif (not send_assignment.nil? and send_assignment.assignment_files.size > 0)
        situation[idx] = "sent"
      elsif (send_assignment.nil? or send_assignment.assignment_files.size == 0) and assignment.schedule.end_date > Date.current
        situation[idx] = "send"
      elsif (send_assignment.nil? or send_assignment.assignment_files.size == 0) and assignment.schedule.end_date < Date.current
        situation[idx] = "not_sent"
      else
        situation[idx] = "-"
      end

    end

    return {"assignments" => assignments, "groups_ids" => groups_ids, "assignments_grades" => assignments_grades, "has_comments" => has_comments, "situation" => situation}
  end

  

  ##
  # Verifica se usuário pode acessar o que está tentando - Atividades e arquivos referentes a elas
  ##
  def user_can_access_assignment(current_user_id, user_id, group_id = nil)
    profile_student   = Profile.select(:id).where("cast(types & '#{Profile_Type_Student}' as boolean)").first
    student_of_class  = !allocations.where(:profile_id => profile_student.id).where(:user_id => current_user_id).empty?
    class_responsible = allocation_tag.is_user_class_responsible?(current_user_id)

    if type_assignment == Individual_Activity
      can_access = (user_id.to_i == current_user_id)
    else
      group      = GroupAssignment.find_by_id_and_assignment_id(group_id, id)
      can_access = group.group_participants.map(&:user_id).include?(current_user_id) unless group.nil?
    end
    return (class_responsible or (student_of_class and can_access))
  end

  ##
  # Arquivos da area publica
  ##
  def self.public_area(group_id, user_id)
    return(PublicFile.all(:conditions => ["users.id = #{user_id} AND allocation_tags.group_id = #{group_id}"], :include => [:allocation_tag, :user], :select => ["attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at"]))
  end
  
end
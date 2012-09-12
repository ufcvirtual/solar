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

  def self.student_activities(group_id, students_id, type_assignment)

    ia = ActiveRecord::Base.connection.select_all <<SQL
    SELECT DISTINCT
           t1.id,
           t1.name,
           t1.enunciation,
           t7.start_date,
           t7.end_date,
           t2.grade,
           t2.id AS send_assignment_id,
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
 LEFT JOIN group_participants  AS t9 ON t9.user_id = #{students_id}
 LEFT JOIN send_assignments    AS t2 ON t2.assignment_id = t1.id AND (t2.group_assignment_id = t9.group_assignment_id OR t2.user_id = #{students_id} )
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
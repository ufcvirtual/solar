class Assignment < ActiveRecord::Base

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
 LEFT JOIN send_assignments   AS t2 ON t2.assignment_id = t1.id AND (t2.group_assignment_id = t5.group_assignment_id OR t2.user_id = #{student_id} )
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
  
end
class GroupAssignment < ActiveRecord::Base

  belongs_to :assignment

  has_many :group_participants
  has_many :send_assignments
  
  #retorna atividades de grupo de acordo com a turma
  def self.all_by_group_id(group_id)
    ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.name,
           t1.enunciation,
           t3.start_date,
           t3.end_date
      FROM assignments     AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN schedules       AS t3 ON t3.id = t1.schedule_id
     WHERE t1.type_assignment=2 and t2.group_id = #{group_id}
     ORDER BY t3.start_date;
SQL
  end

  #retorna participantes de um grupo de trabalho
  def self.all_by_group_assignment_id(group_assignment_id)
    ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.*, t2.name, t2.nick, t2.email, t2.photo_file_name
      FROM group_participants AS t1
      INNER JOIN users AS t2 ON t1.user_id = t2.id
    WHERE t1.group_assignment_id=#{group_assignment_id}
    ORDER BY t2.name;
SQL
  end

end

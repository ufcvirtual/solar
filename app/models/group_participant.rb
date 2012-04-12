class GroupParticipant < ActiveRecord::Base

  belongs_to :group_assignment
  belongs_to :user

  has_many :send_assignments
  
  #retorna participantes de grupo
  def self.all_by_group_assignment(group_assignment_id)
    ActiveRecord::Base.connection.select_all <<SQL
     select gp.id, group_assignment_id, user_id, name, nick, photo_file_name
      from group_participants gp
      inner join users u on gp.user_id = u.id
     WHERE group_assignment_id = #{group_assignment_id}
     ORDER BY u.name;
SQL
  end

end

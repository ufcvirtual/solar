class GroupParticipant < ActiveRecord::Base

  belongs_to :group_assignment
  belongs_to :user

  has_many :sent_assignments
  
  # Retorna participantes do grupo
  def self.all_by_group_assignment(group_assignment_id)
    GroupParticipant.all(
      select: "group_participants.user_id, group_participants.id", 
      joins: :user,
      conditions: {group_assignment_id: group_assignment_id}, 
      order: "users.name")
  end

end

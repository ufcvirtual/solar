class GroupParticipant < ActiveRecord::Base

  belongs_to :group_assignment
  belongs_to :user

  has_many :sent_assignments
  
  # Retorna participantes do grupo
  def self.all_by_group_assignment(group_assignment_id)
    GroupParticipant.all(:select => "user_id, id", :conditions => ["group_assignment_id = #{group_assignment_id}", :order => "users.name", :includes => :user])
  end

  # Retorna o GroupParticipant de um usuário através do trabalho
  # def self.find_by_assignment_id_and_user_id(assignment_id, user_id)
  #   joins(group_assignment: :academic_allocation).where(academic_allocations: {academic_tool_id: assignment_id}, group_participants: {user_id: user_id}).first
  # end

end

class GroupParticipant < ActiveRecord::Base

  belongs_to :group_assignment
  belongs_to :user

  has_many :send_assignments
  
  # Retorna participantes do grupo
  def self.all_by_group_assignment(group_assignment_id)
    GroupParticipant.all(:select => "user_id", :conditions => ["group_assignment_id = #{group_assignment_id}", :order => "users.name", :includes => :user])
  end

end

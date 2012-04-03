class GroupAssignment < ActiveRecord::Base

  belongs_to :assignment

  has_many :group_participants
  has_many :send_assignments
  
end

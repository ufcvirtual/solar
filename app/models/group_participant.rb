class GroupParticipant < ActiveRecord::Base
  belongs_to :group_assignment
  belongs_to :user

  has_many :sent_assignments
end

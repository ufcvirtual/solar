class SendAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :assignment
  belongs_to :group_assignment

  has_many :assignment_comments
  has_many :assignment_files


end

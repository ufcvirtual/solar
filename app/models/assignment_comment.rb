class AssignmentComment < ActiveRecord::Base

  belongs_to :send_assignment
  belongs_to :user

  has_many :comment_files

  validates :comment, :presence => true

end

class AssignmentComment < ActiveRecord::Base

  belongs_to :send_assignment
  belongs_to :user

end

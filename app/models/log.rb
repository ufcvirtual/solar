class Log < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :course
  belongs_to :curriculum_unit  
  belongs_to :group
  
	TYPE = {
    :login => 1,
    :new_user => 2,
    :course_access => 3
  }

end

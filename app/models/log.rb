class Log < ActiveRecord::Base
	after_create :limit_description

	TYPE = {
    :login => 1,
    :new_user => 2,
    :course_access => 3,
		:destroy => 4
	}

	def limit_description
		description = description[0..999] if description
	end

end

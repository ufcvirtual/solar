class Log < ActiveRecord::Base
	TYPE = {
	    :login => 1,
	    :new_user => 2
	  }
end

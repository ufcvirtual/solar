class Course < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers

end

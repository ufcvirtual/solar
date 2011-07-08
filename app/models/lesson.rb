class Lesson < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :schedule

end

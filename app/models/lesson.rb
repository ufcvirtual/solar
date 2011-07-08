class Lesson < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :user

  has_many :schedules

end

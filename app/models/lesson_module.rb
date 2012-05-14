class LessonModule < ActiveRecord::Base
  belongs_to :allocation_tag
  has_many :lessons
end
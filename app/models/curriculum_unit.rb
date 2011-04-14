class CurriculumUnit < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers
  
end

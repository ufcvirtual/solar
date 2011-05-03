class AllocationTag < ActiveRecord::Base
  has_many :allocations
  has_many :lessons
  belongs_to :group
  belongs_to :offer
  belongs_to :curriculum_unit  
  belongs_to :course
end

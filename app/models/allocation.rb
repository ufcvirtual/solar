class Allocation < ActiveRecord::Base

  belongs_to :allocations_tag
  belongs_to :user
  belongs_to :profile
  
end

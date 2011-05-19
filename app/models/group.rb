class Group < ActiveRecord::Base

  has_one :allocation_tag
  belongs_to :offer
  
end

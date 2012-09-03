class Course < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers
  has_many :groups, :through => :offers, :uniq => true
  
end

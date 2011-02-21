class Group < ActiveRecord::Base

  has_many :allocations

  belongs_to :offer

  
end

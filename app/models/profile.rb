class Profile < ActiveRecord::Base

  has_many :allocation
  has_many :permissions

end

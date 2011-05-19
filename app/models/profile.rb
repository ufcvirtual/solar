class Profile < ActiveRecord::Base

  has_many :allocation
  has_many :permissions_resource
  has_many :permissions_menu

end

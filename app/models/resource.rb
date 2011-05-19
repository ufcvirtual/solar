class Resource < ActiveRecord::Base

  has_many :permissions_resources
  belongs_to :menu

end

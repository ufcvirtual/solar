class Resource < ActiveRecord::Base
  has_many :permissions_resources
end

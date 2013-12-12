class Resource < ActiveRecord::Base
  has_and_belongs_to_many :profiles, join_table: "permissions_resources"
end

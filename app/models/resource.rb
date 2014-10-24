class Resource < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_and_belongs_to_many :profiles, join_table: "permissions_resources"
  has_many :menus
end

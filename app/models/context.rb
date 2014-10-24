class Context < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :menus_contexts
  has_many :menus, through: :menus_contexts
end

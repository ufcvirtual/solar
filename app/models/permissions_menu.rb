class PermissionsMenu < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :profile
  belongs_to :menu
end

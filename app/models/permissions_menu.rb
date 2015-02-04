class PermissionsMenu < ActiveRecord::Base

  belongs_to :profile
  belongs_to :menu
end

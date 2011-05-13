class PermissionsResource < ActiveRecord::Base

  belongs_to :resources
  belongs_to :profiles

end
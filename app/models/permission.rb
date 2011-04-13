class Permission < ActiveRecord::Base

  belongs_to :resources
  belongs_to :profiles

end
class Allocation < ActiveRecord::Base

  belongs_to :group
  belongs_to :user
  belongs_to :profile
  
end

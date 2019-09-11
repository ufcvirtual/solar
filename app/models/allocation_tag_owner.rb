class AllocationTagOwner < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :oauth_application

  validates :allocation_tag_id, :oauth_application_id, presence: true

end

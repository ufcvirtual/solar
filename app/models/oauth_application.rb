class OauthApplication < ActiveRecord::Base

  has_many :allocation_tag_owners
  has_many :allocation_tags, through: :allocation_tag_owners

end

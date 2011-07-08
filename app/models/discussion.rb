class Discussion < ActiveRecord::Base
  belongs_to :allocation_tag
  
  has_many :discussion_posts
  has_many :schedules
end

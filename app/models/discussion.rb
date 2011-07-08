class Discussion < ActiveRecord::Base
  belongs_to :allocation_tag
  belongs_to :schedules
  
  has_many :discussion_posts
end

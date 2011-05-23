class DiscussionPost < ActiveRecord::Base
  has_many :children, :class_name => "DiscussionPost", :foreign_key => "father_id"
  belongs_to :father, :class_name => "DiscussionPost"
  
  belongs_to :discussion
end

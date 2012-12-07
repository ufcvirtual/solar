class Post < ActiveRecord::Base

  self.table_name = "discussion_posts"

  has_many :children, :class_name => "Post", :foreign_key => "parent_id"
  has_many :files, :class_name => "PostFile", :foreign_key => "discussion_post_id"

  belongs_to :profile
  belongs_to :parent, :class_name => "Post"
  belongs_to :discussion
  belongs_to :user

  validates :content, :presence => true

  validates_each :discussion_id do |record, attr, value|
    parent = record.parent
    record.errors.add(attr) if not parent.nil? and parent.discussion_id != value
  end

  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level)
  end

end

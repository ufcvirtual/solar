class Post < ActiveRecord::Base

  set_table_name "discussion_posts"

  has_many :children, :class_name => "Post", :foreign_key => "parent_id"
  has_many :files, :class_name => "PostFile", :foreign_key => "discussion_post_id"

  belongs_to :profile
  belongs_to :parent, :class_name => "Post"
  belongs_to :discussion
  belongs_to :user

  validates :content, :presence => true

  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level)
  end

  def self.recent_by_discussions(discussions, limit = 0, content_size = 255)
    query = <<SQL
        SELECT id, user_id, discussion_id, profile_id,
               substring("content" from 0 for #{content_size}) AS content,
               created_at, updated_at, parent_id
          FROM discussion_posts
         WHERE discussion_id IN (#{discussions})
         ORDER BY updated_at DESC
SQL

    query << "LIMIT #{limit}" if limit > 0
    Post.find_by_sql(query)
  end

end

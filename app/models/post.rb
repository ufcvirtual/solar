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

  def to_mobilis
    a_ids = attachments.split(',')
    attachments = []
    PostFile.find(a_ids).map { |file| attachments << {type: file.attachment_content_type, name: file.attachment_file_name, link: Rails.application.routes.url_helpers.download_post_post_file_path(post_id: id, id: file.id)} }

    {
      id: id,
      profile_id: profile_id,
      discussion_id: discussion_id,
      user_id: user_id,
      user_nick: user_nick,
      level: level,
      content: content,
      updated_at: updated_at,
      attachments: attachments
    }
  end

end

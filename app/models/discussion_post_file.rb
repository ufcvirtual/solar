class DiscussionPostFile < ActiveRecord::Base

  belongs_to :discussion_post
  
  validates :attachment_file_name, :presence => true

  validates_attachment_size :attachment, :less_than => 10.megabyte, :message => " "
  has_attached_file :attachment,
    :path => ":rails_root/media/discussion/post/:id_:basename.:extension",
    :url => "/media/discussion/post/:id_:basename.:extension"
end

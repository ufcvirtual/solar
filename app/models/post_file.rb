class PostFile < ActiveRecord::Base

  self.table_name = "discussion_post_files"

  belongs_to :post, :class_name => "Post", :foreign_key => "discussion_post_id"
  
  validates :attachment_file_name, :presence => true
  validates_attachment_size :attachment, :less_than => 10.megabyte, :message => " "
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    :path => ":rails_root/media/discussions/post/:id_:basename.:extension",
    :url => "/media/discussions/post/:id_:basename.:extension"

end

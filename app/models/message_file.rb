class MessageFile < ActiveRecord::Base
  belongs_to :message

  validates_attachment_size :attachment, less_than: 1.megabytes
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    path: ":rails_root/media/messages/:id_:basename.:extension",
    url: "/media/messages/:id_:basename.:extension"

end

class MessageFile < ActiveRecord::Base
  belongs_to :message

  MAX_FILE_SIZE = 1.megabytes

  validates_attachment_size :attachment, less_than: MAX_FILE_SIZE
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    path: ":rails_root/media/messages/:id_:basename.:extension",
    url: "/media/messages/:id_:basename.:extension"

end

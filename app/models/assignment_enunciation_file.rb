class AssignmentEnunciationFile < ActiveRecord::Base
  default_scope order: 'attachment_updated_at DESC'
  
  belongs_to :assignment

  validates :attachment, presence: true

  has_attached_file :attachment,
    :path => ":rails_root/media/assignment/enunciation/:id_:basename.:extension",
    :url => "/media/assignment/enunciation/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 5.megabyte, message: " "

  validates_attachment_content_type_in_black_list :attachment

end

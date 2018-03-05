class AssignmentEnunciationFile < ActiveRecord::Base

  #default_scope order: 'attachment_updated_at DESC'

  belongs_to :assignment

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/enunciation/:id_:basename.:extension",
    url: "/media/assignment/enunciation/:id_:basename.:extension"

  validates :attachment, presence: true
  validates_attachment_size :attachment, less_than: 5.megabyte, message: ""
  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment

  def order
   'attachment_updated_at DESC'
  end
end

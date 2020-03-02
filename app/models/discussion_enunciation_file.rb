class DiscussionEnunciationFile < ActiveRecord::Base
  belongs_to :discussion
  
  has_attached_file :attachment,
    path: ":rails_root/media/discussion/enunciation/:id_:basename.:extension",
    url: "/media/discussion/enunciation/:id_:basename.:extension"

  validates :attachment, presence: true
  validates_attachment_size :attachment, less_than: 5.megabyte, message: ""
  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment

end

class AssignmentFile < ActiveRecord::Base

  belongs_to :send_assignment

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/individual_area/:id_:basename.:extension",
    :url => "/media/portfolio/individual_area/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "
  validates_attachment_content_type :attachment, :content_type =>[
    'image/pjpeg','image/jpeg','image/gif','image/png',
    'application/zip','application/x-rar','application/x-compressed-tar', # arquivos comprimidos
    'application/x-shockwave-flash','application/pdf','application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain'
  ], :message => :invalid_type

end

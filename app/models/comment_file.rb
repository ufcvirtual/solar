class CommentFile < ActiveRecord::Base

  belongs_to :assignment_comment

  validates :attachment_file_name, :presence => true

  ################################
  # attachment files
  ################################

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio_teacher/:assignment_comment_id/:id_:basename.:extension",
    :url => "/media/portfolio_teacher/:assignment_comment_id/:id_:basename.:extension"

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

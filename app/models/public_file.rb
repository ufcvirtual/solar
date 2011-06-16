class PublicFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  ################################
  # attachment files
  ################################

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/public_area/:id_:basename.:extension",
    :url => "/media/portfolio/public_area/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 700.kilobyte

end

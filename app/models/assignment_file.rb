class AssignmentFile < ActiveRecord::Base

  belongs_to :send_assignment

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/individual_area/:id_:basename.:extension",
    :url => "/media/portfolio/individual_area/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 700.kilobyte

end

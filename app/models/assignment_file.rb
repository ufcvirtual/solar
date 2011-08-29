class AssignmentFile < ActiveRecord::Base

  belongs_to :send_assignment

  validates :attachment_file_name, :presence => true

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/individual_area/:id_:basename.:extension",
    :url => "/media/portfolio/individual_area/:id_:basename.:extension"

  # verifica black_list
  before_post_process :validates_black_list

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "

  # Verifica arquivo extensao do arquivo na blacklist
  def validates_black_list
    raise "error_type_file" if Black_List.include?(attachment_content_type)
#    errors.add :file_type if Black_List.include?(attachment_content_type)
  end

end

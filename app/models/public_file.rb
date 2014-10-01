class PublicFile < ActiveRecord::Base
  before_destroy :can_remove?

  belongs_to :user
  belongs_to :allocation_tag

  validates :attachment_file_name, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/public_area/:id_:basename.:extension",
    url: "/media/assignment/public_area/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 5.megabyte, message: " "

  validates_attachment_content_type_in_black_list :attachment

  default_scope order: 'attachment_updated_at DESC'

  def can_remove?
    raise CanCan::AccessDenied unless user_id == User.current.id
  end
end

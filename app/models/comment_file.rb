class CommentFile < ActiveRecord::Base

  #default_scope order: 'attachment_updated_at DESC'

  belongs_to :comment

  has_one :academic_allocation_user, through: :comment

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/comments/:id_:basename.:extension",
    url: "/media/assignment/comments/:id_:basename.:extension"
    
  validates :attachment_file_name, presence: true

  validates_attachment_size :attachment, less_than: 5.megabyte, message: ''
  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment

  def order
   'attachment_updated_at DESC'
  end
end

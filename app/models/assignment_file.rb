class AssignmentFile < ActiveRecord::Base

  FILESIZE = 26.megabyte

  include ControlledDependency
  include SentActivity
  include APILog

  belongs_to :user
  belongs_to :academic_allocation_user

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :assignment, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

  before_save :can_change?, if: -> {merge.nil?}
  before_destroy :can_destroy?

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/sent_assignment_files/:id_:basename.:extension",
    url: "/media/assignment/sent_assignment_files/:id_:basename.:extension"
  
  validates :attachment_file_name, presence: true
  validates :academic_allocation_user_id, presence: true

  validates_attachment_size :attachment, less_than: FILESIZE, message: ' '
  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment

  def order
   'attachment_updated_at DESC'
  end

  def can_change?
    raise 'date_range_expired' unless assignment.in_time?
  end

  def can_destroy?
    raise CanCan::AccessDenied unless user_id == User.current.try(:id)
    raise 'date_range_expired' unless assignment.in_time?
  end

  def delete_with_dependents
    self.delete
  end

end

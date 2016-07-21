class AssignmentFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation_user

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :assignment, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

  before_save :can_change?, if: 'merge.nil?'
  before_destroy :can_change?, :can_destroy?

  validates :attachment_file_name, presence: true
  validates :academic_allocation_user_id, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/sent_assignment_files/:id_:basename.:extension",
    url: "/media/assignment/sent_assignment_files/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 26.megabyte, message: ' '
  validates_attachment_content_type_in_black_list :attachment

  default_scope order: 'attachment_updated_at DESC'

  attr_accessor :merge

  def can_change?
    raise 'date_range' unless assignment.in_time?
  end

  def can_destroy?
    raise CanCan::AccessDenied unless user_id == User.current.try(:id)
    raise 'date_range' unless assignment.in_time?
  end

end

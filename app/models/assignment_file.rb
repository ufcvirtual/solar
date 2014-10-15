class AssignmentFile < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :sent_assignment

  has_one :academic_allocation, through: :sent_assignment

  before_save :can_change?, if: "merge.nil?"
  before_destroy :can_change?, :can_destroy?

  validates :attachment_file_name, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/sent_assignment_files/:id_:basename.:extension",
    url: "/media/assignment/sent_assignment_files/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 5.megabyte, message: " "
  validates_attachment_content_type_in_black_list :attachment

  default_scope order: 'attachment_updated_at DESC'

  attr_accessor :merge

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def allocation_tag
    academic_allocation.allocation_tag
  end

  def can_change?
    raise "date_range_expired" unless assignment.in_time?(allocation_tag.id)
  end

  def can_destroy?
    raise CanCan::AccessDenied unless user_id == User.current.try(:id)
  end

end

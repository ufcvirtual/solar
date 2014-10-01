class AssignmentComment < ActiveRecord::Base
  default_scope order: 'updated_at DESC'

  before_save :can_save?
  before_destroy :can_save?
  before_create :define_user
  
  belongs_to :sent_assignment
  belongs_to :user

  has_many :files, class_name: "CommentFile", dependent: :destroy

  accepts_nested_attributes_for :files, allow_destroy: true, reject_if: proc {|attributes| not attributes.include?(:attachment)}

  validates :comment, presence: true

  def assignment
    sent_assignment.assignment
  end

  def allocation_tag
    sent_assignment.academic_allocation.allocation_tag
  end

  def can_save?
    raise "date_range_expired" unless assignment.in_time?(allocation_tag.id, user_id)
    raise CanCan::AccessDenied unless user_id == User.current.id or new_record?
  end

  def define_user
    self.user_id = User.current.id
  end

end

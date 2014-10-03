class AssignmentComment < ActiveRecord::Base
  default_scope order: 'updated_at DESC'

  before_save :can_save?, if: "merge.nil?"
  before_destroy :can_save?
  before_create :define_user, if: "merge.nil?"
  
  belongs_to :sent_assignment
  belongs_to :user

  has_many :files, class_name: "CommentFile", dependent: :delete_all

  accepts_nested_attributes_for :files, allow_destroy: true, reject_if: proc {|attributes| not attributes.include?(:attachment)}

  validates :comment, presence: true

  attr_accessor :merge

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
    self.user_id = User.current.try(:id)
  end

  def delete_with_dependents
    files.delete_all
    self.delete
  end

end

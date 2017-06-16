class AssignmentComment < ActiveRecord::Base

  default_scope order: 'updated_at DESC'

  before_save :can_save?, if: 'merge.nil?'
  before_destroy :can_save?, if: 'merge.nil?'
  before_create :define_user, if: 'merge.nil?'

  belongs_to :academic_allocation_user
  belongs_to :user

  has_one :academic_allocation, through: :academic_allocation_user
  has_one :assignment, through: :academic_allocation_user

  has_many :files, class_name: 'CommentFile', dependent: :delete_all

  accepts_nested_attributes_for :files, allow_destroy: true, reject_if: proc {|attributes| !attributes.include?(:attachment) || attributes[:attachment] == '0' || attributes[:attachment].blank?}

  validates :comment, presence: true
  validates :academic_allocation_user_id, presence: true

  attr_accessor :merge

  def assignment
    academic_allocation_user.assignment
  end

  def allocation_tag
    academic_allocation_user.academic_allocation.allocation_tag
  end

  def can_save?
    raise 'date_range_expired' unless assignment.in_time?(allocation_tag.id, user_id)
    raise CanCan::AccessDenied unless user_id == User.current.id || new_record?
    true
  end

  def define_user
    self.user_id = User.current.try(:id)
  end

  def delete_with_dependents
    files.delete_all
    self.delete
  end

end

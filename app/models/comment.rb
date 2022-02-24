class Comment < ActiveRecord::Base

  #default_scope order: 'updated_at DESC'

  before_save :can_save?, if: -> {merge.nil?}
  before_destroy :can_save?, if: -> {merge.nil?}
  before_create :define_user, if: -> {merge.nil?}
  after_create :set_acu_status, if: -> {merge.nil?}
  after_destroy :set_acu_status, if: -> {merge.nil?}

  belongs_to :academic_allocation_user, counter_cache: true
  belongs_to :user

  has_one :academic_allocation, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

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
    raise 'date_range_expired' unless allocation_tag.verify_offer_period
    raise CanCan::AccessDenied unless user_id == User.current.id || new_record?
    true
  end

  def set_acu_status
    ac = academic_allocation
    AcademicAllocationUser.create_or_update(ac.academic_tool_type, ac.academic_tool_id, ac.allocation_tag_id, {user_id: academic_allocation_user.user_id, group_assignment_id: academic_allocation_user.group_assignment_id}, {grade: academic_allocation_user.grade, working_hours: academic_allocation_user.working_hours})
  end

  def define_user
    self.user_id = User.current.try(:id)
  end

  def responsibles
    Allocation.responsibles(self.allocation_tag.id).map { |allocation| allocation.user_id }.uniq
  end

  def to_user
    User.find(self.specific_user_id) unless self.specific_user_id.blank?
  end

  def delete_with_dependents
    files.delete_all
    self.delete
  end

  def order
   'updated_at DESC'
  end
end

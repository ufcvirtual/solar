class AcademicAllocationUser < ActiveRecord::Base

  belongs_to :academic_allocation
  belongs_to :user
  belongs_to :group_assignment
	belongs_to :discussion_post

  has_one :allocation_tag, through: :academic_allocation

  validates :user_id, uniqueness: { scope: [:group_assignment_id, :academic_allocation_id] }
  validates :user_id, presence: true, if: 'group_assignment_id.nil?'
  validates :grade, numericality: { greater_than_or_equal_to: 0, smaller_than_or_equal_to: 10 }, if: '!grade.blank?'
  validates :working_hours, numericality: { greater_than_or_equal_to: 0,  only_integer: true }, if: '!working_hours.blank?'
  validate :verify_wh, if: '!working_hours.blank?'
  validate :verify_grade, if: '!grade.blank?'

  before_save :if_group_assignment_remove_user_id
  before_save :verify_profile

  def verify_wh
    if !academic_allocation.frequency
      errors.add(:working_hours, I18n.t('academic_allocation_users.errors.not_frequency')) 
    else
      errors.add(:working_hours, I18n.t('academic_allocation_users.errors.lower_than_max', max: academic_allocation.max_working_hours)) if working_hours > academic_allocation.max_working_hours
    end
  end

  def verify_grade
    if !academic_allocation.evaluative
      errors.add(:grade, I18n.t('academic_allocation_users.errors.not_evaluative'))
    else
      errors.add(:grade, I18n.t('academic_allocation_users.errors.lower_than_10')) if grade > 10
    end
  end

  # if not student, set evaluation as nil
  def verify_profile
    unless user.has_profile_type_at(allocation_tag)
      self.grade = nil
      self.working_hours = nil
    end
  end

  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def users_count
    has_group ? group_assignment.group_participants.count : 1
  end

  def get_user
    (user_id.nil? ? group_assignment.group_participants.map(&:user_id) : [user_id])
  end

  # call after every acu grade change
  def recalculate_final_grade(allocation_tag_id)
    get_user.compact.each do |user|
      allocations = Allocation.includes(:profile).where(user_id: user, status: Allocation_Activated, allocation_tag_id: AllocationTag.find(allocation_tag_id).lower_related).where('cast(profiles.types & ? as boolean)', Profile_Type_Student)
      allocation = allocations.where('final_grade IS NOT NULL').first || allocations.first

      allocation.calculate_final_grade
    end
  end

  def self.create_or_update(tool_type, tool_id, allocation_tag_id, user={user_id: nil, group_assignment_id: nil}, evaluation={grade: nil, working_hours: nil})
    ac = AcademicAllocation.where(academic_tool_id: tool_id, academic_tool_type: tool_type, allocation_tag_id: AllocationTag.find(allocation_tag_id).upper_related).first

    user_id = (user[:group_assignment_id].nil? ? user[:user_id] : nil)
    users_ids = (user[:group_assignment_id].nil? ? [user[:user_id]] : GroupParticipant.where(group_assignment_id: user[:group_assignment_id]).pluck(:user_id))

    if User.find(users_ids.first).has_profile_type_at(allocation_tag_id)
      acu = AcademicAllocationUser.where(academic_allocation_id: ac.id, user_id: user_id, group_assignment_id: user[:group_assignment_id]).first_or_initialize
      tool_type.constantize.update_previous(ac.id, users_ids, acu.id) if acu.new_record?

      acu.grade = evaluation[:grade].blank? ? nil : evaluation[:grade].to_f
      acu.working_hours = evaluation[:working_hours].blank? ? nil : evaluation[:working_hours].to_i

      if acu.save
        acu.recalculate_final_grade(ac.allocation_tag_id)
        return []
      else
        return acu.errors.full_messages
      end
    else
      return [I18n.t('academic_allocation_users.errors.student_group')]
    end
  end

  def self.find_or_create_one(academic_allocation_id, allocation_tag_id, user, group_id=nil, new_object=false)
    if user.has_profile_type_at(allocation_tag_id)
      acu = AcademicAllocationUser.where(academic_allocation_id: academic_allocation_id, user_id: (group_id.nil? ? user.id : nil), group_assignment_id: group_id).first_or_create 
      acu.update_attributes new_after_evaluation: new_object unless acu.grade.blank? && acu.working_hours.blank?
      acu
    end
  end

  def self.find(academic_allocation_id, user_id, group_id=nil, new_object=false)
    acu = AcademicAllocationUser.where(academic_allocation_id: academic_allocation_id, user_id: (group_id.nil? ? user_id : nil), group_assignment_id: group_id).first
    acu.update_attributes new_after_evaluation: new_object unless acu.blank? || (acu.grade.blank? && acu.working_hours.blank?)
    acu
  end 

  def self.set_new_after_evaluation(allocation_tag_id, tool_id, tool_type, users_ids, group_id=nil, new_object=false)
    AcademicAllocationUser.joins(:academic_allocation).where(academic_allocations: {academic_tool_id: tool_id, academic_tool_type: tool_type, allocation_tag_id: allocation_tag_id}, user_id: (group_id.nil? ? users_ids : nil), group_assignment_id: group_id).update_all new_after_evaluation: false
  end

  def self.get_grade_and_wh(user_id, tool, tool_id)
    acu = joins(:academic_allocation).where(academic_allocations: {academic_tool_id: tool_id, academic_tool_type: tool}, user_id: user_id).last
    {grade: acu.try(:grade), wh: acu.try(:working_hours)}
  end 
end

class GroupParticipant < ActiveRecord::Base
  belongs_to :group_assignment
  belongs_to :user

  has_many :academic_allocation_users

  before_create :can_add?, :can_change?, if: 'merge.nil?'
  before_destroy :can_change?, :can_destroy?, if: 'merge.nil?'

  attr_accessor :merge

  def can_change?
    files, at = group_assignment.academic_allocation_user.try(:assignment_files), group_assignment.academic_allocation.allocation_tag.id
    raise 'evaluated' if group_assignment.evaluated?
    raise 'has_files' if (!files.nil? && files.any?) && files.map(&:user_id).include?(user_id)
    raise 'not_student' unless user.has_profile_type_at(at)
  end

  def can_destroy?
    if group_assignment.assignment.ended?
      raise 'alone' if group_assignment.group_participants.size == 1
      ga = GroupAssignment.create(group_name: user.name, academic_allocation_id: group_assignment.academic_allocation_id)
      raise 'already_exists' if ga.id.blank?
      gp = GroupParticipant.new(group_assignment_id: ga.id, user_id: user.id)
      gp.merge = true
      gp.save
    end
  end

  def can_add?
    at = group_assignment.academic_allocation.allocation_tag.id
    assignment = group_assignment.assignment
    raise 'date_range_expired' unless (assignment.in_time?(at) || assignment.will_open?(at, User.current.id))
  end

end

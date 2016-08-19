class GroupParticipant < ActiveRecord::Base
  belongs_to :group_assignment
  belongs_to :user

  has_many :academic_allocation_users

  before_save :can_change?, if: 'merge.nil?'
  before_destroy :can_change?

  attr_accessor :merge

  def can_change?
    group = group_assignment
    files, assignment, at = group.academic_allocation_user.try(:assignment_files), group.assignment, group.academic_allocation.allocation_tag.id
    raise 'date_range_expired' unless (assignment.in_time?(at) || assignment.will_open?(at, User.current.id))
    raise 'evaluated' if group.evaluated?
    raise 'has_files' if (!files.nil? && files.any?) && files.map(&:user_id).include?(user_id)
    raise 'not_student' unless user.has_profile_type_at(at)
  end

end

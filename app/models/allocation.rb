class Allocation < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile

  has_one :course,          through: :allocation_tag, conditions: ["course_id is not null"]
  has_one :curriculum_unit, through: :allocation_tag, conditions: ["curriculum_unit_id is not null"]
  has_one :offer,           through: :allocation_tag, conditions: ["offer_id is not null"]
  has_one :group,           through: :allocation_tag, conditions: ["group_id is not null"]

  has_many :chat_messages
  has_many :chat_participants
  has_many :chat_rooms

  def groups
    allocation_tag.groups unless allocation_tag.nil?
  end

  def self.enrollments(args = {})
    query = ["profile_id = #{Profile.student_profile}", "allocation_tags.group_id IS NOT NULL"]

    unless args.empty? or args.nil?
      query << "groups.offer_id = #{args['offer_id']}"        if args.include?('offer_id')
      query << "groups.id IN (#{args['group_id'].join(',')})" if args.include?('group_id')
      query << "allocations.status = #{args['status']}"       if args.include?('status') and args['status'] != ''
    end

    joins(allocation_tag: {group: :offer}, user: {}).where(query.join(' AND ')).order("users.name")
  end

  def self.have_access?(user_id, allocation_tag_id)
    not(Allocation.find_by_user_id_and_allocation_tag_id(user_id, allocation_tag_id).nil?)
  end

  def user_name
    user.name
  end

  def self.pending(current_user = nil, include_student = false)
    query = (include_student ? "" : "NOT cast(profiles.types & #{Profile_Type_Student} as boolean)")

    # recovers all pending allocations disconsidering (or not) students allocations
    allocations = Allocation.joins(:profile).where("allocations.status = #{Allocation_Pending} OR allocations.status = #{Allocation_Pending_Reactivate}").where(query).order("id")
    # if user was informed and it isn't an admin, remove unrelated allocations; otherwise return allocations
    ((current_user.nil? or current_user.is_admin?) ? allocations : Allocation.remove_unrelated_allocations(current_user, allocations))
  end

  # this method returns an array
  def self.remove_unrelated_allocations(current_user, allocations)
    # recovers only responsible profiles allocations and remove all allocatios which user has no relation with
    allocations.where("cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)").delete_if{
      |allocation| not(current_user.can? :accept_or_reject, Allocation, on: [allocation.allocation_tag_id])
    } unless current_user.nil?
  end

  def curriculum_unit_related
    return curriculum_unit             unless curriculum_unit.nil?
    return offer.curriculum_unit       unless offer.nil?
    return group.offer.curriculum_unit unless group.nil?
  end

  def course_related
    return course             unless course.nil?
    return offer.course       unless offer.nil?
    return group.offer.course unless group.nil?
  end

  def semester_related
    return offer.semester       unless offer.nil?
    return group.offer.semester unless group.nil?
  end

  def offers_related
    return curriculum_unit.offers      unless curriculum_unit.nil?
    return course.offers               unless course.nil?
    return [offer]                     unless offer.nil?
    return [group.offer]               unless group.nil?
  end

  def status_color
    case status.to_i
      when (Allocation_Pending_Reactivate); "#FF6600"
      when (Allocation_Activated); "#006600"
      when (Allocation_Cancelled); "#FF0000"
      when (Allocation_Pending); "#FF6600"
      when (Allocation_Rejected); "#FF0000"
    end
  end

  def self.responsibles(allocation_tags_ids)
    includes(:profile, :user)
      .where("allocation_tag_id IN (?) AND allocations.status = ? AND (cast(profiles.types & ? as boolean))", allocation_tags_ids, Allocation_Activated, Profile_Type_Class_Responsible)
      .order("users.name")
  end

end

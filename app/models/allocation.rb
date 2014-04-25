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
    allocation_tag.groups
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
    allocations = Allocation.joins(:profile).where("allocations.status = #{Allocation_Pending} OR allocations.status = #{Allocation_Pending_Reactivate}").where(query)

    # recovers only responsible profiles allocations and remove all allocatios which user has no relation with
    allocations = allocations.where("cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)").delete_if{
      |allocation| not(current_user.can? :accept_or_reject, Allocation, on: [allocation.allocation_tag_id])
    } unless current_user.nil? or current_user.is_admin? # if user was informed and it isn't an admin

    allocations
  end

  def self.last_changed(current_user = nil)
    # MUST GET FROM LOG (not done yet)
    # get from log just what user did
    # query = ((current_user.nil? or current_user.is_admin?) ? "" : "user_id = #{current_user.id}")
    # ActionLog.where("type_log = #{ALLOCATION_ACCEPTANCE_OR_REJECTION}").order("updated_at desc").limit(15)
    # Allocation_Activated e Allocation_Rejected
    
    Allocation.where("allocations.status = #{Allocation_Activated} OR allocations.status = #{Allocation_Rejected}").order("allocations.updated_at desc").limit(15)
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

end

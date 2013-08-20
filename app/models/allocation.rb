class Allocation < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile

  has_one :course,          :through => :allocation_tag, :conditions => ["course_id is not null"]
  has_one :curriculum_unit, :through => :allocation_tag, :conditions => ["curriculum_unit_id is not null"]
  has_one :offer,           :through => :allocation_tag, :conditions => ["offer_id is not null"]
  has_one :group,           :through => :allocation_tag, :conditions => ["group_id is not null"]

  has_many :chat_messages
  has_many :chat_participants

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

end

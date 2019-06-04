class UserAccessLast < ActiveRecord::Base
	belongs_to :academic_allocation
  belongs_to :user

  has_one :allocation_tag, through: :academic_allocation
  has_one :exam,            -> { where academic_allocations: { academic_tool_type: 'Exam' }}, through: :academic_allocation
  has_one :assignment,      -> { where academic_allocations: { academic_tool_type: 'Assignment' }}, through: :academic_allocation
  has_one :chat_room,       -> { where academic_allocations: { academic_tool_type: 'ChatRoom' }}, through: :academic_allocation
  has_one :schedule_event,  -> { where academic_allocations: { academic_tool_type: 'ScheduleEvent' }}, through: :academic_allocation
  has_one :discussion,      -> { where academic_allocations: { academic_tool_type: 'Discussion' }}, through: :academic_allocation


  def self.find_or_create_or_update_one(academic_allocation_id,  user_id, update_date=false)
  	ual = UserAccessLast.where(academic_allocation_id: academic_allocation_id, user_id: user_id).first_or_create
  	copy_ual = ual.dup
  	if update_date
  		ual.date_last_access = DateTime.now
  		ual.save!
  	end
  	copy_ual
  end

end
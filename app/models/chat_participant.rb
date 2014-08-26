class ChatParticipant < ActiveRecord::Base

  belongs_to :academic_allocation, conditions: {academic_tool_type: 'ChatRoom'}
  belongs_to :allocation

  has_one :user, through: :allocation
  has_one :chat_room, through: :academic_allocation

end

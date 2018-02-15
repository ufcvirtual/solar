class ChatMessage < ActiveRecord::Base
  belongs_to :academic_allocation, -> { where academic_tool_type: 'ChatRoom' }
  belongs_to :allocation
  belongs_to :academic_allocation_user

  has_one :user, through: :allocation
  has_one :chat_room, through: :academic_allocation
end

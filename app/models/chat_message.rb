class ChatMessage < ActiveRecord::Base
  belongs_to :academic_allocation, conditions: {academic_tool_type: 'ChatRoom'}
  belongs_to :allocation
  belongs_to :user

  def chat
    ChatRoom.find(academic_allocation.academic_tool_id)
  end

end

class ChatParticipant < ActiveRecord::Base
  belongs_to :chat_room
  belongs_to :allocation

  has_one :user, through: :allocation
end

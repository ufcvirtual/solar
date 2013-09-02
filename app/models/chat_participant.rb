class ChatParticipant < ActiveRecord::Base
  belongs_to :chat_room
  belongs_to :allocation, foreign_key: :allocation_id

  has_one :user, through: :allocation
end

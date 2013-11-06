class ChatMessage < ActiveRecord::Base
  belongs_to :chat_room
  belongs_to :allocation
  belongs_to :user
end

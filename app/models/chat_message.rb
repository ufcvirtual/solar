class ChatMessage < ActiveRecord::Base
  # attr_accessible :title, :body

  belongs_to :chat_room
  belongs_to :allocation
  belongs_to :user

end

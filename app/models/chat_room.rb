class ChatRoom < ActiveRecord::Base
  # attr_accessible :title, :body

  has_many :chat_messages
  has_many :chat_participants

  # belongs_to :academic_allocation

end

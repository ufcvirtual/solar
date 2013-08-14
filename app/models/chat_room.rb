class ChatRoom < ActiveRecord::Base
  include RelatedToGroup

  # attr_accessible :title, :body

  has_many :chat_messages
  has_many :chat_participants

  has_many :academic_allocations, as: :academic_tool

end

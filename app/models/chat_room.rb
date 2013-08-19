class ChatRoom < ActiveRecord::Base
  
  GROUP_PERMISSION = true
  include ToolsAssociation

  # attr_accessible :title, :body

  has_many :chat_messages
  has_many :chat_participants

  has_many :academic_allocations, as: :academic_tool

end

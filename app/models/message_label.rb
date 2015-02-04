class MessageLabel < ActiveRecord::Base

  belongs_to :user

  has_many :user_message_labels, dependent: :destroy
  has_many :user_messages, through: :user_message_labels
  has_many :messages, through: :user_messages
end

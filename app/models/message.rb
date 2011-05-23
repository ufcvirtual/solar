class Message < ActiveRecord::Base
  has_many :message_files
  has_many :user_message
end

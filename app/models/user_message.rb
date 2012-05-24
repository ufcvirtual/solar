class UserMessage < ActiveRecord::Base
  has_many :user_message_labels

  belongs_to :user
  belongs_to :message
end

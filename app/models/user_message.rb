class UserMessage < ActiveRecord::Base
  belongs_to :message
  belongs_to :user
  has_many   :user_message_labels
end

class UserMessageLabel < ActiveRecord::Base
  belongs_to :user_message
  belongs_to :message_label
end

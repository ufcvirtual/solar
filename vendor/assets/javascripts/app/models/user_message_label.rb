class UserMessageLabel < ActiveRecord::Base
  belongs_to :user_message
  belongs_to :message_label

  attr_accessible :user_message_id, :message_label_id
end

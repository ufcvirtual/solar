class UserMessageLabel < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user_message
  belongs_to :message_label
end

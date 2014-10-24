class UserMessage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :message

  has_many :user_message_labels
  has_many :message_labels, through: :user_message_labels
end

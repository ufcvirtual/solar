class MessageLabel < ActiveRecord::Base
  has_many :user_message_labels

  belongs_to :user
  belongs_to :allocation_tag
end

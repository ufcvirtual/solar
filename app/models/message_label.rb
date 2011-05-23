class MessageLabel < ActiveRecord::Base
  belongs_to :user
  belongs_to :allocation_tag
  has_many :user_message_label
end

class UserContact < ActiveRecord::Base
  belongs_to :user, class_name: "User", foreign_key: "user_id"
  belongs_to :user_related, class_name: "User", foreign_key: "user_related_id"

  attr_accessible :user_id, :user_related_id
end

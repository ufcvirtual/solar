class UserContact < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :user_related, class_name: "User", foreign_key: "user_related_id"
end

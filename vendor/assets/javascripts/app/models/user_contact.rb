class UserContact < ActiveRecord::Base
  belongs_to :user_id, class_name: "UserContact"
  belongs_to :user_related_id, class_name: "UserContact"
end

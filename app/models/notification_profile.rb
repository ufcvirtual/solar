class NotificationProfile < ActiveRecord::Base
  belongs_to :profile
  belongs_to :notification
end

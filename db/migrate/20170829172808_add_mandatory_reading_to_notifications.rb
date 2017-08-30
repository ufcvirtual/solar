class AddMandatoryReadingToNotifications < ActiveRecord::Migration
  def change
  	add_column :notifications, :mandatory_reading, :boolean, default: false
  end
end

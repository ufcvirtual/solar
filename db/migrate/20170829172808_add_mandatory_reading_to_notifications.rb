class AddMandatoryReadingToNotifications < ActiveRecord::Migration[5.0]
  def change
  	add_column :notifications, :mandatory_reading, :boolean, default: false
  end
end

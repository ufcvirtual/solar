class CreateNotificationFiles < ActiveRecord::Migration
  def change
    create_table :notification_files do |t|
      t.references :notification
      t.attachment :file

      t.timestamps
    end
    add_index :notification_files, :notification_id
  end
end

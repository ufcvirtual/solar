class CreateReadNotifications < ActiveRecord::Migration
  def change
    create_table :read_notifications, id: false do |t|
      t.references :notification, null: false
      t.foreign_key :notifications

      t.references :user, null: false
      t.foreign_key :users

      t.timestamps
    end

    add_index :read_notifications, [:notification_id, :user_id], unique: true
  end
end



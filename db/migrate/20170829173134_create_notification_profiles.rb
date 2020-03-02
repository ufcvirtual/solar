class CreateNotificationProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :notification_profiles do |t|
      t.references :profile
      t.references :notification
    end
    #add_index :notification_profiles, :profile_id
    #add_index :notification_profiles, :notification_id
  end
end

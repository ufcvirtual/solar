class CreateScheduleEventFiles < ActiveRecord::Migration[5.0]
  def self.up
    create_table :schedule_event_files do |t|
      t.integer :user_id
      t.integer :academic_allocation_user_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.foreign_key :users
      t.foreign_key :academic_allocation_users
      t.timestamps
    end
  end

  def self.down
    drop_table :schedule_event_files
  end
end

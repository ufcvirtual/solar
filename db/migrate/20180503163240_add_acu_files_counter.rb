class AddAcuFilesCounter < ActiveRecord::Migration
  def up
    add_column :academic_allocation_users, :schedule_event_files_count, :integer, default: 0, null: false
    execute "UPDATE academic_allocation_users SET schedule_event_files_count=(
CASE WHEN (SELECT COUNT(schedule_event_files.id) FROM schedule_event_files WHERE schedule_event_files.academic_allocation_user_id = academic_allocation_users.id)<1 THEN 0
ELSE (SELECT COUNT(schedule_event_files.id) FROM schedule_event_files WHERE schedule_event_files.academic_allocation_user_id = academic_allocation_users.id) END);"
    # execute "UPDATE academic_allocation_users SET schedule_event_files_count=(SELECT COUNT(schedule_event_files.id) FROM schedule_event_files WHERE schedule_event_files.academic_allocation_user_id = academic_allocation_users.id);"
  end

  def down
    remove_column :academic_allocation_users, :schedule_event_files_count
  end
end

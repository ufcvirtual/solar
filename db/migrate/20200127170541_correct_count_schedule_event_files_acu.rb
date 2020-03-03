class CorrectCountScheduleEventFilesAcu < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE academic_allocation_users SET schedule_event_files_count=(
CASE WHEN (SELECT COUNT(schedule_event_files.id) FROM schedule_event_files WHERE schedule_event_files.academic_allocation_user_id = academic_allocation_users.id)<1 THEN 0
ELSE (SELECT COUNT(schedule_event_files.id) FROM schedule_event_files WHERE schedule_event_files.academic_allocation_user_id = academic_allocation_users.id) END);"
  end
end

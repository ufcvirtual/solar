class AddOnlineFileCorrectionToScheduleEventFiles < ActiveRecord::Migration[5.1]
  def up
    add_column :schedule_event_files, :file_correction, :text
  end

  def down
    remove_column :schedule_event_files, :file_correction
  end
end

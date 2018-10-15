class ChangeAttachmentFileNameScheduleEventFiles < ActiveRecord::Migration
  def change
    change_column :schedule_event_files, :attachment_file_name, :text, limit: 450
  end
end

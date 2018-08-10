class AddHasFileToPrintScheduleEvents < ActiveRecord::Migration
  def up
    add_column :schedule_events, :content_exam, :text
  end

  def down
    remove_column :schedule_events, :content_exam
  end
end

class AddHasFileToPrintScheduleEvents < ActiveRecord::Migration[5.1]
  def up
    add_column :schedule_events, :content_exam, :text
  end

  def down
    remove_column :schedule_events, :content_exam
  end
end

class AddTimestamps < ActiveRecord::Migration[5.1]
  def up
    change_table(:discussions) { |t| t.timestamps }
    change_table(:assignments) { |t| t.timestamps }
    change_table(:chat_rooms) { |t| t.timestamps }
    change_table(:schedule_events) { |t| t.timestamps }

    Discussion.update_all created_at: DateTime.now, updated_at: DateTime.now
    Assignment.update_all created_at: DateTime.now, updated_at: DateTime.now
    ChatRoom.update_all created_at: DateTime.now, updated_at: DateTime.now
    ScheduleEvent.update_all created_at: DateTime.now, updated_at: DateTime.now
  end
end

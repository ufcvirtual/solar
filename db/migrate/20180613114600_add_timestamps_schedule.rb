class AddTimestampsSchedule < ActiveRecord::Migration
  def change
    change_table(:schedules) { |t| t.timestamps }

    # Schedule.update_all created_at: DateTime.now, updated_at: DateTime.now
  end
end

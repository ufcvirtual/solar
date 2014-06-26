class AddIntegrationFlagScheduleEvents < ActiveRecord::Migration
  def up
  	add_column :schedule_events, :integrated, :boolean, default: false
  end

  def down
  	remove_column :schedule_events, :integrated, :boolean
  end
end

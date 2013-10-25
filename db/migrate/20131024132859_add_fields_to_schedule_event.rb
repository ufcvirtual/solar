class AddFieldsToScheduleEvent < ActiveRecord::Migration
  def change
    change_table :schedule_events do |t|
      t.integer :type_event, null: false, default: 2
      t.string :start_hour
      t.string :end_hour
      t.string :place
    end
  end
end


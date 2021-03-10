class CreateScheduleEvents < ActiveRecord::Migration[5.1]
  def self.up
    create_table :schedule_events do |t|
      t.string :title , :limit => 100
      t.text :description
      t.integer :allocation_tag_id
      t.integer :schedule_id
    end

    add_foreign_key :schedule_events, :allocation_tags
    add_foreign_key :schedule_events, :schedules
  end

  def self.down
    drop_table :schedule_events
  end
end

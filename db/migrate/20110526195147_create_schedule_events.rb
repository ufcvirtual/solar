class CreateScheduleEvents < ActiveRecord::Migration
  def self.up
    create_table :schedule_events do |t|
      t.string :title , :limit => 100
      t.text :description
      
      t.integer :schedule_id

    end
  end

  def self.down
    drop_table :schedule_events
  end
end

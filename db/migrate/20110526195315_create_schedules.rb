class CreateSchedules < ActiveRecord::Migration[5.1]
  def self.up
    create_table :schedules do |t|
    t.date :start_date
    t.date :end_date
    end
  end

  def self.down
    drop_table :schedules
  end
end

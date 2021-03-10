class AlterScheduleDate < ActiveRecord::Migration[5.1]
  def self.up
    change_column :schedules, :start_date, :datetime
    change_column :schedules, :end_date,   :datetime
  end

  def self.down
    change_column :schedules, :start_date, :date
    change_column :schedules, :end_date,   :date
  end
end

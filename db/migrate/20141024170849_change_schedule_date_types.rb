class ChangeScheduleDateTypes < ActiveRecord::Migration[5.1]
  def up
  	change_column :schedules, :start_date, :date
  	change_column :schedules, :end_date, :date
  end
end

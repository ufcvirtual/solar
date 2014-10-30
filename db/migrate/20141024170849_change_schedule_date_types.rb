class ChangeScheduleDateTypes < ActiveRecord::Migration
  def change
  	change_column :schedules, :start_date, :date
  	change_column :schedules, :end_date, :date
  end
end

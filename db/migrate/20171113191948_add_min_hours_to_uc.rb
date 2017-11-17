class AddMinHoursToUc < ActiveRecord::Migration
  def change
  	add_column :curriculum_units, :min_hours, :integer
  end
end

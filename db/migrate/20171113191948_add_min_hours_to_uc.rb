class AddMinHoursToUc < ActiveRecord::Migration[5.0]
  def change
  	add_column :curriculum_units, :min_hours, :integer
  end
end

class ChangMaxWorkingHoursTypeInAcademicAllocations < ActiveRecord::Migration
  def up
  	change_column :academic_allocations, :max_working_hours, :decimal, default: 1, :precision => 5, :scale => 2
  end

  def down
  	change_column :academic_allocations, :max_working_hours, :integer, default: 1
  end
end

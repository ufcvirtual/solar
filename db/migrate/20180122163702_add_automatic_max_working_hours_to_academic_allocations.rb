class AddAutomaticMaxWorkingHoursToAcademicAllocations < ActiveRecord::Migration
  def change
    add_column :academic_allocations, :frequency_automatic, :boolean, default: false
  end
end

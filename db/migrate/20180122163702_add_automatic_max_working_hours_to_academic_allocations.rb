class AddAutomaticMaxWorkingHoursToAcademicAllocations < ActiveRecord::Migration[5.1]
  def change
    add_column :academic_allocations, :frequency_automatic, :boolean, default: false
  end
end

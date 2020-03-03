class AddSupportHelpToAcademicAllocations < ActiveRecord::Migration[5.0]
  def change
  	add_column :academic_allocations, :support_help, :integer
  end
end

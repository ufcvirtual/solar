class AddSupportHelpToAcademicAllocations < ActiveRecord::Migration
  def change
  	add_column :academic_allocations, :support_help, :integer
  end
end

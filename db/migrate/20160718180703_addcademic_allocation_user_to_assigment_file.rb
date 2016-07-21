class AddcademicAllocationUserToAssigmentFile < ActiveRecord::Migration
  def change
    add_column :assignment_files, :academic_allocation_user_id, :integer
  end
end

class AddcademicAllocationUserToAssigmentComment < ActiveRecord::Migration
  def change
    add_column :assignment_comments, :academic_allocation_user_id, :integer
  end
end

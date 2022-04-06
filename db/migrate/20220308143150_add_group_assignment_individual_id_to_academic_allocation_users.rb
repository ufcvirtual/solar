class AddGroupAssignmentIndividualIdToAcademicAllocationUsers < ActiveRecord::Migration[5.1]
  def up
  	add_column :academic_allocation_users, :group_individual_assignment_id, :integer, null: true, default: nil
  end

  def down
  	remove_column :academic_allocation_users, :group_individual_assignment_id, :integer
  end
end

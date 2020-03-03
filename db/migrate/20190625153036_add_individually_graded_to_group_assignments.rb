class AddIndividuallyGradedToGroupAssignments < ActiveRecord::Migration[5.0]
  def up
  	add_column :group_assignments, :individually_graded, :boolean, default: false
  end

  def down
  	remove_column :group_assignments, :individually_graded, :boolean
  end
end

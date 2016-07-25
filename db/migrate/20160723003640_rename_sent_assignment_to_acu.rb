class RenameSentAssignmentToAcu < ActiveRecord::Migration
  def up
    drop_table :academic_allocation_users
    rename_table :sent_assignments, :academic_allocation_users
  end

  def down
  end
end

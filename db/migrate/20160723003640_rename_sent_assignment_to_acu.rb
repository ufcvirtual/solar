class RenameSentAssignmentToAcu < ActiveRecord::Migration[5.1]
  def up
    drop_table :academic_allocation_users
    rename_index :sent_assignments, 'index_sent_assignments_on_academic_allocation_id_and_user_id', 'index_sent_assignments_aa_id_and_u_id'
    rename_table :sent_assignments, :academic_allocation_users
  end

  def down
  end
end

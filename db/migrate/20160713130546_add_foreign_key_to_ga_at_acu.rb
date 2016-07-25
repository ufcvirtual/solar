class AddForeignKeyToGaAtAcu < ActiveRecord::Migration
  def change
    # add_index :group_assignments, [:group_participant_id, :group_assignment_id, :academic_allocation_id], name: 'user_group_ac_idx', unique: true
    # add_index :academic_allocation_users, [:user_id, :group_assignment_id, :academic_allocation_id], name: 'user_group_ac_idx', unique: true
    # change_table :academic_allocation_users do |t|
    #     t.foreign_key :group_assignments
    # end
  end
end

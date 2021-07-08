class RenameSendAssignmentsToSentAssignments < ActiveRecord::Migration[5.1]
  def self.up
    remove_foreign_key :send_assignments, :assignments
    remove_foreign_key :send_assignments, :users

    execute "ALTER TABLE send_assignments DROP CONSTRAINT IF EXISTS unq_send_assignment;"
    execute "DROP INDEX IF EXISTS unq_send_assignment;"
    
    rename_table :send_assignments, :sent_assignments

    add_index :sent_assignments, [:assignment_id, :user_id], unique: true
    
    add_foreign_key :sent_assignments, :assignments
    add_foreign_key :sent_assignments, :users
   
    # remove_foreign_key :assignment_files, :send_assignments #o nome da tabela referenciada eh sent_assignments, pois nesse ponto ja tinha sido renomeada no metodo rename_table mais acima.
    remove_foreign_key :assignment_files, :sent_assignments
    rename_column :assignment_files, :send_assignment_id, :sent_assignment_id
    add_foreign_key :assignment_files, :sent_assignments

    # remove_foreign_key :assignment_comments, :send_assignments
    remove_foreign_key :assignment_comments, :sent_assignments
    rename_column :assignment_comments, :send_assignment_id, :sent_assignment_id    
    add_foreign_key :assignment_comments, :sent_assignments
  end 

  def self.down
    remove_foreign_key :sent_assignments, :assignments
    remove_foreign_key :sent_assignments, :users

    remove_index :sent_assignments, column: [:assignment_id, :user_id]

    rename_table :sent_assignments, :send_assignments

    execute "ALTER TABLE send_assignments ADD CONSTRAINT unq_send_assignment UNIQUE(assignment_id, user_id);"
    
    add_foreign_key :send_assignments, :assignments
    add_foreign_key :send_assignments, :users

    rename_column :assignment_files, :sent_assignment_id, :send_assignment_id
    remove_foreign_key :assignment_files, :sent_assignments
    add_foreign_key :assignment_files, :send_assignments

    rename_column :assignment_comments, :sent_assignment_id, :send_assignment_id
    remove_foreign_key :assignment_comments, :sent_assignments
    add_foreign_key :assignment_comments, :send_assignments
  end
end

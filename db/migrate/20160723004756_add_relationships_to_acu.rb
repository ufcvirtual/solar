class AddRelationshipsToAcu < ActiveRecord::Migration[5.1]
  def change
    #remove_foreign_key :academic_allocation_users, name: :sent_assignments_academic_allocation_id_fk
    #remove_foreign_key :academic_allocation_users, name: :sent_assignments_user_id_fk
    remove_foreign_key :assignment_comments, column: :sent_assignment_id
    remove_foreign_key :assignment_files, column: :sent_assignment_id
    remove_foreign_key :assignment_webconferences, column: :sent_assignment_id

    change_table :academic_allocation_users do |t|
      t.integer :working_hours
      t.integer :status
      t.boolean :new_after_evaluation, default: false
      t.timestamps
    end
    add_foreign_key :academic_allocation_users, :users
    add_foreign_key :academic_allocation_users, :academic_allocations

    change_table :exam_user_attempts do |t|
      t.integer :academic_allocation_user_id, null: false
    end
    add_foreign_key :exam_user_attempts, :academic_allocation_users

    change_table :assignment_comments do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
    end
    add_foreign_key :assignment_comments, :academic_allocation_users

    change_table :assignment_files do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
    end
    add_foreign_key :assignment_files, :academic_allocation_users

    change_table :assignment_webconferences do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
    end
    add_foreign_key :assignment_webconferences, :academic_allocation_users]

    change_table :log_actions do |t|
      t.integer :academic_allocation_user_id
    end
    add_foreign_key :log_actions, :academic_allocation_users
  end
end

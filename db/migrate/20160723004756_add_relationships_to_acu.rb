class AddRelationshipsToAcu < ActiveRecord::Migration
  def change
    remove_foreign_key :academic_allocation_users, name: :sent_assignments_academic_allocation_id_fk
    remove_foreign_key :academic_allocation_users, name: :sent_assignments_user_id_fk
    remove_foreign_key :assignment_comments, name: :assignment_comments_sent_assignment_id_fk
    remove_foreign_key :assignment_files, name: :assignment_files_sent_assignment_id_fk
    remove_foreign_key :assignment_webconferences, name: :assignment_webconferences_sent_assignment_id_fk

    change_table :academic_allocation_users do |t|
      t.integer :working_hours
      t.integer :status
      t.boolean :new_after_evaluation, default: false
      t.foreign_key :users
      t.foreign_key :academic_allocations
      t.timestamps
    end

    change_table :exam_user_attempts do |t|
      t.integer :academic_allocation_user_id, null: false
      t.foreign_key :academic_allocation_users
    end

    change_table :assignment_comments do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      t.foreign_key :academic_allocation_users
    end

    change_table :assignment_files do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      t.foreign_key :academic_allocation_users
    end

    change_table :assignment_webconferences do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      t.foreign_key :academic_allocation_users
    end

    change_table :log_actions do |t|
      t.integer :academic_allocation_user_id
      t.foreign_key :academic_allocation_users
    end
  end
end

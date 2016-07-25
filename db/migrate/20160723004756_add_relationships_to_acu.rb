class AddRelationshipsToAcu < ActiveRecord::Migration
  def change
    change_table :academic_allocation_users do |t|
      t.integer :working_hours
      t.integer :status
      t.boolean :new_after_evaluation, default: false
      t.timestamps
    end

    change_table :exam_user_attempts do |t|
      t.integer :academic_allocation_user_id, null: false
      # t.foreign_key :academic_allocation_users
    end

    change_table :assignment_comments do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      # t.foreign_key :academic_allocation_users
    end

    change_table :assignment_files do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      # t.foreign_key :academic_allocation_users
    end

    change_table :assignment_webconferences do |t|
      t.rename :sent_assignment_id, :academic_allocation_user_id
      # t.foreign_key :academic_allocation_users
    end

    change_table :log_actions do |t|
      t.integer :academic_allocation_user_id
      # t.foreign_key :academic_allocation_users
    end
  end
end

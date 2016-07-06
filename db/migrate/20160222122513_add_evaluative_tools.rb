class AddEvaluativeTools < ActiveRecord::Migration
  def up
    change_table :academic_allocations do |t|
      t.boolean :evaluative, default: false
      t.boolean :frequency, default: false
      t.boolean :final_exam, default: false
      t.integer :max_working_hours, default: 0
      t.integer :equivalent_academic_allocation_id
      t.integer :weigth, default: 0
      t.integer :final_weight, default: 100
    end

    create_table :academic_allocation_users do |t|
      t.integer :academic_allocation_id, null: false
      t.foreign_key :academic_allocations
      t.integer :user_id, null: false
      t.foreign_key :users
      t.integer :group_assignment_id, null: true
      t.integer :grade
      t.integer :attempts, default: 1
      t.integer :working_hours
      t.integer :status
      t.boolean :new_after_evaluation, default: false
    end
  end

  def down
    remove_column :academic_allocations, :evaluative
    remove_column :academic_allocations, :frequency
    remove_column :academic_allocations, :final_exam
    remove_column :academic_allocations, :max_working_hours
    remove_column :academic_allocations, :equivalent_academic_allocation_id
    remove_column :academic_allocations, :weigth

    drop_table :academic_allocation_users
  end
end

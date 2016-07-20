class DropExamUserTable < ActiveRecord::Migration
  def up
    drop_table :exam_users
  end

  def down
    create_table :exam_users do |t|
      t.integer :user_id, null: false
      t.foreign_key :users
      t.float :grade
      t.datetime :start
      t.datetime :end
      t.boolean :complete, default: false
      t.integer :academic_allocation_id, null: false
      t.foreign_key :academic_allocations
      t.timestamps
    end
    add_index :exam_users, :user_id
    add_index :exam_users, :academic_allocation_id
  end
end

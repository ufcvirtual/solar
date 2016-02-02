class ExamUserAttempts < ActiveRecord::Migration
  def change
    create_table :exam_user_attempts do |t|
      t.integer :exam_user_id, null: false
      t.foreign_key :exam_users
      t.float :grade
      t.datetime :start
      t.datetime :end
      t.boolean :complete, default: false
      t.timestamps
    end
     add_index :exam_user_attempts, :exam_user_id

    remove_column :exam_users, :grade
    remove_column :exam_users, :start
    remove_column :exam_users, :end
    remove_column :exam_users, :complete

    remove_column :exam_responses, :exam_user_id
    add_column :exam_responses, :exam_user_attempt_id, :integer, null: false
    add_index :exam_responses, :exam_user_attempt_id
  end
end

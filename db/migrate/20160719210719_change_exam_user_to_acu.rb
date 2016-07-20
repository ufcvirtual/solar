class ChangeExamUserToAcu < ActiveRecord::Migration
  def up
    change_table :exam_user_attempts do |t|
      t.integer :academic_allocation_user_id, null: false
      t.foreign_key :academic_allocation_users

      t.remove :exam_user_id
    end
  end

  def down
    change_table :exam_user_attempts do |t|
      t.integer :exam_user_id, null: false
      t.foreign_key :exam_users

      t.remove :academic_allocation_user_id
    end
    remove_foreign_key :exam_user_attempts, :academic_allocation_users
  end
end

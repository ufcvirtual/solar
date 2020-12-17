class CreateAssignmentComments < ActiveRecord::Migration
  def self.up
    create_table :assignment_comments do |t|
      t.integer :send_assignment_id, :null => false
      t.integer :user_id, :null => false
      t.text :comment
    end

    add_foreign_key :assignment_comments, :send_assignments
    add_foreign_key :assignment_comments, :users
  end

  def self.down
    drop_table :assignment_comments
  end
end

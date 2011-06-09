class CreateSendAssignments < ActiveRecord::Migration
  def self.up
    create_table :send_assignments do |t|
      t.integer :assignment_id, :null => false
      t.integer :user_id, :null => false
      t.text :comment
    end
  end

  def self.down
    drop_table :send_assignments
  end
end

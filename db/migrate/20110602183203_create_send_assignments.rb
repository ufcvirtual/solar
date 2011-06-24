class CreateSendAssignments < ActiveRecord::Migration
  def self.up
    create_table :send_assignments do |t|
      t.integer :assignment_id, :null => false
      t.integer :user_id, :null => false
      t.text :comment
      t.float :grade
    end

    execute <<-SQL
      ALTER TABLE send_assignments ADD CONSTRAINT unq_send_assignment UNIQUE(assignment_id, user_id);
    SQL
  end

  def self.down
    drop_table :send_assignments
  end
end

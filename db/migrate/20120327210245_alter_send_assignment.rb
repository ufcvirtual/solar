class AlterSendAssignment < ActiveRecord::Migration[5.1]
  def self.up
    change_table :send_assignments do |t|
      t.integer :group_assignment_id
    end
  end

  def self.down
    change_table :send_assignments do |t|
      t.remove :group_assignment_id
    end
  end
end

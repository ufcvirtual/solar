class CreateGroupAssignments < ActiveRecord::Migration[5.0]
  def self.up
    create_table :group_assignments do |t|
      t.integer  :assignment_id, :null => false
      t.string   :group_name, :limit => 255, :null => false
      t.datetime :group_updated_at
    end

    add_foreign_key :group_assignments, :assignments
  end

  def self.down
    drop_table   :group_assignments
  end
end

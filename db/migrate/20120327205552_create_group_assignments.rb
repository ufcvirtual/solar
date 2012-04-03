class CreateGroupAssignments < ActiveRecord::Migration
  def self.up
    create_table :group_assignments do |t|
      t.integer  :assignment_id, :null => false
      t.string   :group_name, :limit => 255, :null => false
      t.datetime :group_updated_at
    end
  end

  def self.down
    drop_table   :group_assignments
  end
end

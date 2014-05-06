class ChangeLogActionsColumn < ActiveRecord::Migration
  def up
    # remove_index :log_actions, :tool_id # doesn't exist
    change_table :log_actions do |t|
      t.rename :tool_id, :academic_allocation_id
      t.integer :allocation_tag_id
      t.index :academic_allocation_id
      t.index :allocation_tag_id
    end
  end

  def down
    remove_index :log_actions, :academic_allocation_id
    remove_index :log_actions, :allocation_tag_id
    change_table :log_actions do |t|
      t.rename :academic_allocation_id, :tool_id
      t.remove :allocation_tag_id
      t.index :tool_id
    end
  end
end

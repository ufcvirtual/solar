class RemoveColumnFromSendAssignment < ActiveRecord::Migration
  def up
  	remove_column :send_assignments, :comment
  end

  def down
  	add_column :send_assignments, :comment, :text
  end
end

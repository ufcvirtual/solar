class AddServerToAssignmentWebconferences < ActiveRecord::Migration
  def change
    add_column :assignment_webconferences, :server, :integer
    add_index :assignment_webconferences, :server
  end
end

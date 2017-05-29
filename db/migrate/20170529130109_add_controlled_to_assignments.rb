class AddControlledToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :controller, :boolean, default: false
  end
end

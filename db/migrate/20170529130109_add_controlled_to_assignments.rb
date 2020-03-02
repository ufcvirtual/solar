class AddControlledToAssignments < ActiveRecord::Migration[5.0]
  def change
    add_column :assignments, :controller, :boolean, default: false
  end
end

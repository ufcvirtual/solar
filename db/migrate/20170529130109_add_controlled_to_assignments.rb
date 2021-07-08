class AddControlledToAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :controller, :boolean, default: false
  end
end

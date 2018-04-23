class ChangeDefaultTypeOfAssignment < ActiveRecord::Migration[5.0]
  def up
    change_column :assignments, :type_assignment, :integer, default: 0
  end

  def down
    change_column :assignments, :type_assignment, :integer, default: 1
  end
end

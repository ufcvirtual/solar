class ChangeNameLengthFromAssignments < ActiveRecord::Migration
  def up
    change_column :assignments, :name, :string, limit: 1024
  end

  def down
    change_column :assignments, :name, :string, limit: 100
  end
end

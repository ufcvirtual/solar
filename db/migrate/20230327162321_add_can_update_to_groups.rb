class AddCanUpdateToGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :can_update, :boolean, default: false
  end
end

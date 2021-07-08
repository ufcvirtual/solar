class AddMergedInfoToGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :main_group_id, :integer, null: true
    add_foreign_key :groups, :groups, column: :main_group_id
  end
end

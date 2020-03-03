class AddOriginGroupAtAllocation < ActiveRecord::Migration[5.0]
  def change
    add_column :allocations, :origin_group_id, :integer, null: true
    add_foreign_key :allocations, :groups, column: :origin_group_id
  end
end

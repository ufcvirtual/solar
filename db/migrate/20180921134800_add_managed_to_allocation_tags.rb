class AddManagedToAllocationTags < ActiveRecord::Migration[5.0]
  def change
    add_column :allocation_tags, :managed, :boolean
  end
end

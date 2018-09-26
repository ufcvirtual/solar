class AddManagedToAllocationTags < ActiveRecord::Migration
  def change
    add_column :allocation_tags, :managed, :boolean
  end
end

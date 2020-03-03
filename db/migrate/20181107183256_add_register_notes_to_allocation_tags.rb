class AddRegisterNotesToAllocationTags < ActiveRecord::Migration[5.0]
  def change
    add_column :allocation_tags, :bloq_register_notes, :boolean, default: false, null: false
  end
end

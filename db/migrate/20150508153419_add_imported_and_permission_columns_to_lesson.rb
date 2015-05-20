class AddImportedAndPermissionColumnsToLesson < ActiveRecord::Migration
  def up
    change_table :lessons do |t|
      t.integer :imported_from_id, null: true
      t.boolean :receive_updates, default: false
    end
    add_index :lessons, :imported_from_id
  end

  def down
    remove_column :lessons, :imported_from_id
    remove_column :lessons, :receive_updates
  end
end

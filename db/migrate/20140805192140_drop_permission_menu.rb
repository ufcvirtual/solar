class DropPermissionMenu < ActiveRecord::Migration[5.1]
  def up
    drop_table :permissions_menus
  end

  def down
    create_table :permissions_menus do |t|
      t.references :profile
      t.references :menu
    end
  end
end

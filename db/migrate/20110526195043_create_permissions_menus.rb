class CreatePermissionsMenus < ActiveRecord::Migration
  def self.up
    create_table "permissions_menus", :id => false do |t|
      t.integer "profile_id", :null => false
      t.integer "menu_id",    :null => false
    end

	add_foreign_key(:permissions_menus, :profiles)
	add_foreign_key(:permissions_menus, :menus)
  end

  def self.down
    drop_table "permissions_menus"
  end
end

class CreateTablePermissionsMenus < ActiveRecord::Migration
  def self.up
    create_table :permissions_menus, {:id => false} do |t|
      t.references :profiles
      t.references :menus
    end

    execute <<-SQL
    ALTER TABLE permissions_menus ADD PRIMARY KEY (profiles_id, menus_id)
SQL
  end

  def self.down
    drop_table :permissions_menus
  end
end

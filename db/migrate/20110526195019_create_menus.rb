class CreateMenus < ActiveRecord::Migration[5.1]
  def self.up
    create_table "menus" do |t|
      t.integer "resource_id"
      t.string  "name",         :limit => 100
      t.string  "link"
      t.boolean "status",       :default => true
      t.integer "context_id"
      t.integer "order",        :default => 999,  :null => false
    end

    execute <<-SQL
      ALTER TABLE menus ADD COLUMN father_id INTEGER NULL REFERENCES menus(id)
    SQL

    add_foreign_key :permissions_menus, :profiles
    add_foreign_key :permissions_menus, :menus
  end

  def self.down
    drop_table "menus"
  end
end

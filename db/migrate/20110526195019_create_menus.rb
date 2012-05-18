class CreateMenus < ActiveRecord::Migration
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

    add_foreign_key(:menus, :resources)
    add_foreign_key(:menus, :contexts)
  end

  def self.down
    drop_table "menus"
  end
end

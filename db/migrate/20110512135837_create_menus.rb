class CreateMenus < ActiveRecord::Migration
  def self.up
    create_table :menus do |t|
      t.references :resources
      t.string :name, :limit => 100
      t.string :link, :limit => 255
      t.boolean :status, :default => true
    end

    execute <<-SQL
      ALTER TABLE menus ADD COLUMN father_id INTEGER NULL REFERENCES menus(id)
    SQL
  end

  def self.down
    drop_table :menus
  end
end

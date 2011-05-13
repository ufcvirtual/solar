class AlterTableMenusAddColumns < ActiveRecord::Migration
  def self.up
    change_table :menus do |t|
      t.references :contexts
      t.integer :order, :default => 999, :null => false
    end
  end

  def self.down
    change_table :menus do |t|
      t.remove :contexts_id
      t.remove :order
    end
  end
end

class AlterTableResourcesAddColumnStatus < ActiveRecord::Migration
  def self.up
    change_table :resources do |t|
      t.boolean :status, :default => true
    end
  end

  def self.down
    change_table :resources do |t|
      t.remove :status
    end
  end
end

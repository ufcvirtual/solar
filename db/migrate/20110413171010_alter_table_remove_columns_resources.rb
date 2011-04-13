class AlterTableRemoveColumnsResources < ActiveRecord::Migration
  def self.up
    change_table :resources do |t|
      t.remove :created_at
      t.remove :updated_at
      t.boolean :per_id, :default => false
    end
  end

  def self.down
    change_table :resources do |t|
      t.timestamps
      t.remove :per_id
    end
  end
end

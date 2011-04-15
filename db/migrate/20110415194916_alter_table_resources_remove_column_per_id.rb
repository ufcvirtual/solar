class AlterTableResourcesRemoveColumnPerId < ActiveRecord::Migration
  def self.up
  	change_table :resources do |t|
      t.remove :per_id
    end  	
  end

  def self.down
    change_table :resources do |t|
      t.boolean :per_id, :default => false
    end
  end
end

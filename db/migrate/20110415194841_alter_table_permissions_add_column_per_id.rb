class AlterTablePermissionsAddColumnPerId < ActiveRecord::Migration
  def self.up
  	change_table :permissions do |t|
      t.boolean :per_id, :default => false
    end
  end

  def self.down
  	change_table :permissions do |t|
      t.remove :per_id
    end  
  end
end

class AlterTablePermissionsAddColumnStatus < ActiveRecord::Migration
  def self.up
    change_table :permissions do |t|
      t.boolean :status, :default => true
    end
  end

  def self.down
    change_table :permissions do |t|
      t.remove :status
    end
  end
end

class AlterTableProfilesAddColumnStatus < ActiveRecord::Migration
  def self.up
    change_table :profiles do |t|
      t.remove :created_at
      t.remove :updated_at
      t.boolean :status, :default => true
    end
  end

  def self.down
    change_table :profiles do |t|
      t.remove :status

      t.timestamps
    end
  end
end

class CreateTableAllocation < ActiveRecord::Migration
  def self.up
    create_table :allocations do |t|
      t.references :users
      t.references :classes
      t.references :profiles
      t.boolean :status,     :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :allocations
  end
end

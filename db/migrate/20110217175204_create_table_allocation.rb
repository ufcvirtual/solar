class CreateTableAllocation < ActiveRecord::Migration
  def self.up
    create_table :allocations do |t|
      t.integer :user_id,    :null => false
      t.integer :class_id,   :null => false
      t.integer :profile_id, :null => false
      t.boolean :status,     :default => true
      t.timestamps
    end

    add_index :allocations, ["user_id"], :name => "index_allocation_on_user"
    add_index :allocations, ["class_id"], :name => "index_allocation_on_class"
    add_index :allocations, ["profile_id"], :name => "index_allocation_on_profile"
  end

  def self.down
    drop_table :allocations
  end
end

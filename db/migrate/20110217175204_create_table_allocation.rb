class CreateTableAllocation < ActiveRecord::Migration
  def self.up
    create_table :allocation do |t|
      t.integer :user_id,    :null => false
      t.integer :class_id,   :null => false
      t.integer :profile_id, :null => false
      t.boolean :status,     :default => true
      t.timestamps
    end

    add_index :allocation, ["user_id"], :name => "index_allocation_on_user"
    add_index :allocation, ["class_id"], :name => "index_allocation_on_class"
    add_index :allocation, ["profile_id"], :name => "index_allocation_on_profile"
  end

  def self.down
    drop_table :allocation
  end
end

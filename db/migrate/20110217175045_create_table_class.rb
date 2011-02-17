class CreateTableClass < ActiveRecord::Migration
  def self.up
     create_table :class do |t|
      t.integer :offer_id, :null => false
      t.string  :code
      t.boolean :status,   :default => true
      t.timestamps
    end

    add_index :class, ["offer_id"], :name => "index_class_on_offer"
  end

  def self.down
    drop_table :class
  end
end

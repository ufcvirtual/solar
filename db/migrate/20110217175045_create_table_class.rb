class CreateTableClass < ActiveRecord::Migration
  def self.up
     create_table :classes do |t|
      t.integer :offer_id, :null => false
      t.string  :code
      t.boolean :status,   :default => true
      t.timestamps
    end

    add_index :classes, ["offer_id"], :name => "index_class_on_offer"    
  end

  def self.down    
    drop_table :classes
  end
end

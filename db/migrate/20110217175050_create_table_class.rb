class CreateTableClass < ActiveRecord::Migration
  def self.up
     create_table :classes do |t|
      t.references :offers
      t.string  :code
      t.boolean :status,   :default => true
      t.timestamps
    end
  end

  def self.down    
    drop_table :classes
  end
end

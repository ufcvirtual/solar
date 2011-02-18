class CreateTableGroup < ActiveRecord::Migration
  def self.up
     create_table :groups do |t|
      t.references :offers
      t.string  :code
      t.boolean :status,   :default => true
      t.timestamps
    end
  end

  def self.down    
    drop_table :groups
  end
end

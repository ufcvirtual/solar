class CreateTableProfile < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.string :name, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end

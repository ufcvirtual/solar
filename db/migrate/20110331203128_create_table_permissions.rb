class CreateTablePermissions < ActiveRecord::Migration
  def self.up
  	 create_table :permissions do |t|
       	t.references :profiles
      	t.references :resources
     end
  end

  def self.down
  	drop_table :permissions
  end
end

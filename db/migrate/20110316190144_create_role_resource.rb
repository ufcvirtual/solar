class CreateRoleResource < ActiveRecord::Migration
  def self.up
    create_table :role_resource do |t|
        t.integer :role_id, :null=> false;
        t.integer :resource_id, :null=>false;
    end
    add_index :role_resource, ["role_id"], :name => "index_role_on_role_resource"
    add_index :role_resource, ["resource_id"], :name => "index_resource_on_role_resource"
  end

  def self.down
    drop_table :role_resource
  end
end

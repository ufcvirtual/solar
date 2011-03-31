class DestroyRoleTables < ActiveRecord::Migration
	def self.up
		drop_table :roles
		drop_table :role_user
		drop_table :resources
		drop_table :role_resource
	end

	def self.down
		create_table :roles do |t|
			t.string  :name     , :null=>false
			t.timestamps
		end

		create_table :role_user do |t|
			t.integer :user_id    , :null=>false
			t.integer :role_id    , :null=>false
		end

		add_index :role_user, ["user_id"], :name => "index_user_on_role_user", :unique => true
		add_index :role_user, ["role_id"], :name => "index_role_on_role_user", :unique => true

		create_table :resources do |t|
			t.string :description,   :null => false
			t.string :action, :null => false
			t.string :controller, :null => false
			t.timestamps
		end

		create_table :role_resource do |t|
			t.integer :role_id, :null=> false;
			t.integer :resource_id, :null=>false;
		end
		add_index :role_resource, ["role_id"], :name => "index_role_on_role_resource"
		add_index :role_resource, ["resource_id"], :name => "index_resource_on_role_resource"
	end
end

class CreateRoleUser < ActiveRecord::Migration
  def self.up
     create_table :role_user do |t|
       t.integer :user_id    , :null=>false
       t.integer :role_id    , :null=>false
     end

     add_index :role_user, ["user_id"], :name => "index_user_on_role_user", :unique => true
     add_index :role_user, ["role_id"], :name => "index_role_on_role_user", :unique => true
  end

  def self.down
      drop_table :role_user
  end
end

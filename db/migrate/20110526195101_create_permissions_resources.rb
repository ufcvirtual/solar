class CreatePermissionsResources < ActiveRecord::Migration
  def self.up
    create_table "permissions_resources", :id => false do |t|
      t.integer "profile_id",   :null => false
      t.integer "resource_id",  :null => false
      t.boolean "per_id",       :default => false, :references => nil
      t.boolean "status",       :default => true
    end

  end

  def self.down
    drop_table "permissions_resources"
  end
end

class CreatePermissionsResources < ActiveRecord::Migration
  def self.up
    create_table "permissions_resources", :id => false do |t|
      t.integer "profile_id",   :null => false
      t.integer "resource_id",  :null => false
      t.boolean "per_id",       :default => false
      t.boolean "status",       :default => true
    end

    add_foreign_key(:permissions_resources, :profiles)
    add_foreign_key(:permissions_resources, :resources)
  end

  def self.down
    drop_table "permissions_resources"
  end
end

class AlterTablePermissions < ActiveRecord::Migration
  def self.up
    remove_column :permissions, :id
    execute 'ALTER TABLE permissions ADD PRIMARY KEY (profiles_id, resources_id)';
  end

  def self.down
    execute 'ALTER TABLE permissions DROP CONSTRAINT permissions_pkey'
    add_column :permissions, :id, :primary_key
  end
end

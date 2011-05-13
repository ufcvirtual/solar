class RenameTablePermissionToPermissionResources < ActiveRecord::Migration
  def self.up
    execute <<-SQL
    ALTER TABLE permissions RENAME TO permissions_resources
SQL
  end

  def self.down
    execute <<-SQL
    ALTER TABLE permissions_resources RENAME TO permissions
SQL
  end
end

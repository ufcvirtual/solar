class AlterTablePermissionsAddColumnStatus < ActiveRecord::Migration
  def self.up
    change_table :permissions do |t|
      t.boolean :status, :default => true
    end

    execute <<-SQL
      ALTER TABLE permissions ADD PRIMARY KEY (profiles_id, resources_id)
    SQL

  end

  def self.down
    change_table :permissions do |t|
      t.remove :status
    end

    execute <<-SQL
      ALTER TABLE permissions DROP CONSTRAINT permissions_pkey
    SQL
  end
end

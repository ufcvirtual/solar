class AlterLogsColumnDescription < ActiveRecord::Migration
  def up  	
    execute "ALTER TABLE logs RENAME COLUMN message TO description"
    change_column :logs, :description, :string, :limit => 1000, :null => true
  end

  def down
    execute "ALTER TABLE logs RENAME COLUMN description TO message"
    change_column :logs, :message, :string, :limit => 255, :null => true
  end
end
    
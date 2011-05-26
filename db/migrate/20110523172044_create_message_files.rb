class CreateMessageFiles < ActiveRecord::Migration
  def self.up
    create_table :message_files do |t|
      t.references :message
      t.string     :original_name, :null => false, :limit => 120
    end
  end

  def self.down
    drop_table :message_files
  end
end

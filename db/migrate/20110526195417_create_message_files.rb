class CreateMessageFiles < ActiveRecord::Migration
  def self.up
    create_table "message_files" do |t|
      t.integer "message_id"
      t.string  "original_name", :limit => 120, :null => false
    end
  end

  def self.down
    drop_table "message_files"
  end
end

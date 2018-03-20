class CreateMessageFiles < ActiveRecord::Migration
  def self.up
    create_table "message_files" do |t|
      t.integer  "message_id"
      t.string   "message_file_name"
      t.string   "message_content_type"
      t.integer  "message_file_size"
      t.datetime "message_updated_at"
    end

    add_foreign_key :message_files, :messages
  end

  def self.down
    drop_table "message_files"
  end
end

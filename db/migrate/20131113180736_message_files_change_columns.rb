class MessageFilesChangeColumns < ActiveRecord::Migration
  def up
    change_table :message_files do |t|
      t.rename :message_file_name,    :attachment_file_name
      t.rename :message_content_type, :attachment_content_type
      t.rename :message_file_size,    :attachment_file_size
      t.rename :message_updated_at,   :attachment_updated_at
    end
  end

  def down
    change_table :message_files do |t|
      t.rename :attachment_file_name,    :message_file_name
      t.rename :attachment_content_type, :message_content_type
      t.rename :attachment_file_size,    :message_file_size
      t.rename :attachment_updated_at,   :message_updated_at
    end
  end
end

class ChangeChatTables < ActiveRecord::Migration
  def up
    rename_column :chat_rooms, :type, :chat_type
    rename_column :chat_messages, :type, :message_type
    add_column :chat_participants, :id, :primary_key
  end

  def down
    rename_column :chat_rooms, :chat_type, :type
    rename_column :chat_messages, :message_type, :type
    remove_column :chat_participants, :id
  end
end

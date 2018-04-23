class RemoveChatRoomIdFromChatMessages < ActiveRecord::Migration[5.0]
  def up
    remove_column :chat_messages, :chat_room_id
  end

  # def down
  # end
end

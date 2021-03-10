class AddColumnHistChatRoomsIdToLogNavigationSubs < ActiveRecord::Migration[5.1]
  def change
    add_column :log_navigation_subs, :hist_chat_rooms_id, :integer
  end
end

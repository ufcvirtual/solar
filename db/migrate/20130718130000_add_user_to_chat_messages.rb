class AddUserToChatMessages < ActiveRecord::Migration[5.1]
  def up
    change_table :chat_messages do |t|
      t.references :user, null: true
    end
    add_foreign_key :chat_messages, :users
  end
  def down
    remove_foreign_key :chat_messages, :user
    remove_column :chat_messages, :user_id
  end
end

class AddUserToChatMessages < ActiveRecord::Migration
  def up
    change_table :chat_messages do |t|
      t.references :user, null: true
      t.foreign_key :users
    end
  end
  def down
    remove_foreign_key :chat_messages, :user
    remove_column :chat_messages, :user_id
  end
end

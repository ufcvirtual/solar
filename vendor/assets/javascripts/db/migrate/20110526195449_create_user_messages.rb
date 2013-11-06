class CreateUserMessages < ActiveRecord::Migration
  def self.up
    create_table "user_messages" do |t|
      t.integer "message_id"
      t.integer "user_id"
      t.integer "status"
    end

    add_foreign_key(:user_messages, :messages)
    add_foreign_key(:user_messages, :users)
  end

  def self.down
    drop_table "user_messages"
  end
end

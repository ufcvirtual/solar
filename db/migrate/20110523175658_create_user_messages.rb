class CreateUserMessages < ActiveRecord::Migration
  def self.up
    create_table :user_messages do |t|
      t.references :messages
      t.references :users
      t.integer    :status
    end
  end

  def self.down
    drop_table :user_messages
  end
end

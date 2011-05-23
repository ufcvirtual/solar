class CreateUserMessageLabels < ActiveRecord::Migration
  def self.up
    create_table :user_message_labels, {:id => false} do |t|
      t.references :user_messages
      t.references :message_labels
    end
    
    execute <<-SQL
      ALTER TABLE user_message_labels ADD PRIMARY KEY (user_messages_id, message_labels_id)
    SQL
  end

  def self.down
    drop_table :user_message_labels
  end
end

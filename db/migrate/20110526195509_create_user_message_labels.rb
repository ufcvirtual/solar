class CreateUserMessageLabels < ActiveRecord::Migration
  def self.up
    create_table "user_message_labels", :id => false do |t|
      t.integer "user_message_id",  :null => false
      t.integer "message_label_id", :null => false
    end

    execute <<-SQL
      ALTER TABLE user_message_labels ADD PRIMARY KEY (user_message_id, message_label_id);
    SQL

    add_foreign_key(:user_message_labels, :user_messages)
    add_foreign_key(:user_message_labels, :message_labels)
  end

  def self.down
    drop_table "user_message_labels"
  end
end

class CreateUserMessageLabels < ActiveRecord::Migration
  def self.up
    create_table :user_message_labels, {:id => false} do |t|
      t.references :user_message
      t.references :message_label
    end
    
    execute <<-SQL
      ALTER TABLE user_message_labels ADD PRIMARY KEY (user_message_id, message_label_id)
    SQL
  end

  def self.down
    drop_table :user_message_labels
  end
end

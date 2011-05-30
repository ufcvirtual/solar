class CreateUserMessageLabels < ActiveRecord::Migration
  def self.up
    create_table "user_message_labels", :id => false do |t|
      t.integer "user_message_id",  :null => false
      t.integer "message_label_id", :null => false
    end
  end

  def self.down
    drop_table "user_message_labels"
  end
end

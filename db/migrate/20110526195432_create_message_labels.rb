class CreateMessageLabels < ActiveRecord::Migration[5.0]
  def self.up
    create_table "message_labels" do |t|
      t.integer "user_id"
      t.boolean "label_system", :default => true
      t.string  "title", :limit => 120, :null => false
    end

    add_foreign_key :message_labels, :users
  end

  def self.down
    drop_table "message_labels"
  end
end

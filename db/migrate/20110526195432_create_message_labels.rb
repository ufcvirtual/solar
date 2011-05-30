class CreateMessageLabels < ActiveRecord::Migration
  def self.up
    create_table "message_labels" do |t|
      t.integer "user_id"
      t.integer "allocation_tag_id"
      t.string  "title", :limit => 120, :null => false
    end
  end

  def self.down
    drop_table "message_labels"
  end
end

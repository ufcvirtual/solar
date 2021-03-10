class CreateMessages < ActiveRecord::Migration[5.1]
  def self.up
    create_table "messages" do |t|
      t.string   "subject"
      t.text     "content"
      t.datetime "send_date"
    end
  end

  def self.down
    drop_table "messages"
  end
end

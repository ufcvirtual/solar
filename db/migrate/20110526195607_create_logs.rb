class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table "logs" do |t|
      t.integer  "log_type"
      t.string   "message"
      t.integer  "user_id", :references => nil
      t.integer  "profile_id", :references => nil
      t.integer  "course_id", :references => nil
      t.integer  "class_id", :references => nil
    end
  end

  def self.down
    drop_table "logs"
  end
end

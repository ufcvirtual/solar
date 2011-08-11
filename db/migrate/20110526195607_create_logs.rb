class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table "logs" do |t|
      t.integer  "log_type", :default => 1 # login
      t.integer  "user_id", :references => nil
      t.string   "message"
      t.integer  "course_id", :references => nil
      t.integer  "curriculum_unit_id", :references => nil
      t.integer  "group_id", :references => nil
      t.string  "session_id", :references => nil
      t.datetime "created_at"
    end
  end

  def self.down
    drop_table "logs"
  end
end

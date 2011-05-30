class CreateLessonLogs < ActiveRecord::Migration
  def self.up
    create_table "lesson_logs" do |t|
      t.integer  "lesson_id"
      t.integer  "allocation_id"
      t.datetime "access_date",    :null => false
    end
  end

  def self.down
    drop_table "lesson_logs"
  end
end

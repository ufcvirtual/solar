class CreateLessonLogs < ActiveRecord::Migration
  def self.up
    create_table "lesson_logs" do |t|
      t.integer  "lesson_id", :null => false
      t.integer  "allocation_id"
      t.datetime "access_date",    :null => false
    end

    add_foreign_key(:lesson_logs, :lessons)
    add_foreign_key(:lesson_logs, :allocations)
  end

  def self.down
    drop_table "lesson_logs"
  end
end

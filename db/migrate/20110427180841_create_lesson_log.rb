class CreateLessonLog < ActiveRecord::Migration
  def self.up
    create_table :lesson_logs do |t|
      t.references :lessons
      t.references :allocations
      t.datetime :access_date, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :lesson_logs
  end
end
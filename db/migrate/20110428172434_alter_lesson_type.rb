class AlterLessonType < ActiveRecord::Migration
  def self.up
    change_table :lessons do |t|
      t.rename :type, :type_lesson
    end
  end

  def self.down
    change_table :lessons do |t|
      t.rename :type_lesson, :type
    end
  end
end

class AlterLessonToModule < ActiveRecord::Migration
  def self.up
    change_table :lessons do |t|
      t.integer :lesson_module_id
      t.remove  :allocation_tag_id
    end

    add_foreign_key(:lessons, :lesson_modules)
  end

  def self.down
    change_table :lessons do |t|
      t.remove :lesson_module_id
      t.integer :allocation_tag_id
    end
  end
end

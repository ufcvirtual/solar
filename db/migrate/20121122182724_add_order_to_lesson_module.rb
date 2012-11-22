class AddOrderToLessonModule < ActiveRecord::Migration
  def up
  	add_column :lesson_modules, :order, :integer, :null => false
  end

  def down
  	remove_column :lesson_modules, :order
  end
end

class AddOrderToLessonModule < ActiveRecord::Migration[5.0]
  def up
  	add_column :lesson_modules, :order, :integer
  end

  def down
  	remove_column :lesson_modules, :order
  end
end

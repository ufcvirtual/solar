class AddResponsiveToLesson < ActiveRecord::Migration
  def change
    add_column :lessons, :responsive, :boolean, default: false, null: false
  end
end

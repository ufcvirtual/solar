class AddResponsiveToLesson < ActiveRecord::Migration[5.0]
  def change
    add_column :lessons, :responsive, :boolean, default: false, null: false
  end
end

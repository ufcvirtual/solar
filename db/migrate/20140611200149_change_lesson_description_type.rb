class ChangeLessonDescriptionType < ActiveRecord::Migration[5.1]
  def up
  	change_column :lessons, :description, :text
  end

  def down
  	change_column :lessons, :description, :string
  end
end

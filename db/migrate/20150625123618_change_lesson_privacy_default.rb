class ChangeLessonPrivacyDefault < ActiveRecord::Migration[5.0]
  def up
    change_column :lessons, :privacy, :boolean, default: false, null: false
  end
end

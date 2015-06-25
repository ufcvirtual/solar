class ChangeLessonPrivacyDefault < ActiveRecord::Migration
  def up
    change_column :lessons, :privacy, :boolean, default: false, null: false
  end
end

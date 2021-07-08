class IsRecordedDefaultTrue < ActiveRecord::Migration[5.1]
  def change
    change_column :assignment_webconferences, :is_recorded, :boolean, default: true
    change_column :webconferences, :is_recorded, :boolean, default: true
  end
end

class IsRecordedDefaultTrue < ActiveRecord::Migration
  def change
    change_column :assignment_webconferences, :is_recorded, :boolean, default: true
    change_column :webconferences, :is_recorded, :boolean, default: true
  end
end

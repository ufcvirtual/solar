class AddIsRecordedToWebconference < ActiveRecord::Migration[5.0]
  def change
    add_column :webconferences, :is_recorded, :boolean, :default => false
  end
end

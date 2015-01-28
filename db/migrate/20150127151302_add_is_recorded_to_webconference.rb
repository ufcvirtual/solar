class AddIsRecordedToWebconference < ActiveRecord::Migration
  def change
    add_column :webconferences, :is_recorded, :boolean, :default => false
  end
end

class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.string :title, null: false
      t.text :description, null: false

      t.references :schedule, null: false
      t.foreign_key :schedules

      t.timestamps
    end
  end
end

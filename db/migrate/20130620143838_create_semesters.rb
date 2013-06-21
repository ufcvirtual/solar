class CreateSemesters < ActiveRecord::Migration
  def change
    create_table :semesters do |t|
      t.string :name, null: false
      t.integer :offer_schedule_id, null: false
      t.integer :enrollment_schedule_id, null: false

      t.foreign_key :schedules, column: 'offer_schedule_id'
      t.foreign_key :schedules, column: 'enrollment_schedule_id'
    end
  end
end

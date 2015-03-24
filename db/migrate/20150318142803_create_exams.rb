class CreateExams < ActiveRecord::Migration
  def change
    create_table :exams do |t|
      t.string :name, limit: 100, null: false
      t.text :description, null: false
      t.integer :duration
      t.string  :start_hour
      t.string  :end_hour
      t.boolean :random_questions, default: false
      t.boolean :raffle_order, default: false
      t.boolean :auto_correction, default: false
      t.integer :number_questions
      t.integer :attempts, default: 1
      t.boolean :result_email, default: false
      t.integer :schedule_id
      t.foreign_key :schedules
      t.timestamps
    end
  end
end


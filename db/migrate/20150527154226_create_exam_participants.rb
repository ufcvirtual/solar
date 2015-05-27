class CreateExamParticipants < ActiveRecord::Migration
  def change
    create_table :exam_participants do |t|
      t.references :user, null: false
      t.references :exam, null: false
      t.foreign_key :users
      t.foreign_key :exams
      t.datetime :created_at
    end
  end
end

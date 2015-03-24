class CreateExamQuestions < ActiveRecord::Migration
  def change
    create_table :exam_questions do |t|
      t.integer :exam_id, null: false
      t.foreign_key :exams
      t.integer :question_id, null: false
      t.foreign_key :questions
      t.float :score, default: 0
      t.integer :order
      t.boolean :annulled, default: false
      t.timestamps
    end
    add_index :exam_questions, :exam_id
    add_index :exam_questions, :question_id
  end
end

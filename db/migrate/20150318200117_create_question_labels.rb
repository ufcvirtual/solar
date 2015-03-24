class CreateQuestionLabels < ActiveRecord::Migration
  def change
    create_table :question_labels do |t|
      t.string :name
      t.timestamps
    end

    create_table :question_labels_questions, id: false do |t|
      t.integer :question_id, null: false
      t.foreign_key :questions
      t.integer :question_label_id, null: false
      t.foreign_key :question_labels
    end

    add_index :question_labels_questions, :question_id
    add_index :question_labels_questions, :question_label_id
  end
end

class CreateExamResponsesQuestionItems < ActiveRecord::Migration
  def change
    create_table :exam_responses_question_items, :id => false do |t|
      t.integer :exam_response_id
      t.integer :question_item_id
    end
    add_foreign_key(:exam_responses_question_items, :exam_responses)
    add_foreign_key(:exam_responses_question_items, :question_items)
    add_index :exam_responses_question_items, :question_item_id
  end

  def down
        drop_table :exam_responses_question_items
  end
end

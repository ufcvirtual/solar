class AddQuestionIdToExamResponses < ActiveRecord::Migration
  def change
    add_column :exam_responses, :question_id, :integer, null: false
    add_index :exam_responses, :question_id

    change_column :exam_responses, :question_item_id, :integer, null: true

    remove_column :exam_responses, :response_time
  end
end

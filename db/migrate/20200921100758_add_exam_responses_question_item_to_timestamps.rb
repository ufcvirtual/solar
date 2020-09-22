class AddExamResponsesQuestionItemToTimestamps < ActiveRecord::Migration
  def change
    change_table :exam_responses_question_items do |t|
      t.timestamps
    end
    ExamResponsesQuestionItem.update_all(created_at: Time.now, updated_at: Time.now)
	end
end

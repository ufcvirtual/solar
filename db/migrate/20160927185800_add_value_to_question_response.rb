class AddValueToQuestionResponse < ActiveRecord::Migration
  def up
    add_column :exam_responses_question_items, :value, :boolean
    add_column :exam_responses_question_items, :id, :primary_key
  end
  def down
    remove_column :exam_responses_question_items, :value
    remove_column :exam_responses_question_items, :id
  end
end

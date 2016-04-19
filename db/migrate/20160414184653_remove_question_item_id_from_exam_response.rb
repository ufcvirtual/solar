class RemoveQuestionItemIdFromExamResponse < ActiveRecord::Migration
  def up
    remove_column :exam_responses, :question_item_id
    remove_column :exam_responses, :value
  end

  def down
    add_column :exam_responses, :question_item_id, :integer
    add_column :exam_responses, :value, :boolean
  end
end
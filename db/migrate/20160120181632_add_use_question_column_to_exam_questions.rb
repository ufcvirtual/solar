class AddUseQuestionColumnToExamQuestions < ActiveRecord::Migration[5.1]
  def change
    add_column :exam_questions, :use_question, :boolean, default: false
  end
end

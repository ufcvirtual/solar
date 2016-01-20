class AddUseQuestionColumnToExamQuestions < ActiveRecord::Migration
  def change
    add_column :exam_questions, :use_question, :boolean, default: false
  end
end

class AddTextIdToQuestions < ActiveRecord::Migration[5.1]
  def change
    add_column :questions, :question_text_id, :integer
    add_foreign_key :questions, :question_texts
  end
end

class AddTextIdToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :question_text_id, :integer
    add_foreign_key :questions, :question_texts
  end
end

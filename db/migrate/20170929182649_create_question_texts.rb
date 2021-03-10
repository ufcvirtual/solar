class CreateQuestionTexts < ActiveRecord::Migration[5.1]
  def change
    create_table :question_texts do |t|
      t.text :text
      
      t.timestamps
    end
  end
end

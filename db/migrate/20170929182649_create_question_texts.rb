class CreateQuestionTexts < ActiveRecord::Migration
  def change
    create_table :question_texts do |t|
      t.text :text
      
      t.timestamps
    end
  end
end

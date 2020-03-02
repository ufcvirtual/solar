class CreateQuestionAudios < ActiveRecord::Migration[5.0]
  def change
    create_table :question_audios do |t|
      t.integer :question_id, null: false
      t.foreign_key :questions
      t.timestamps
    end
    add_attachment :question_audios, :audio
  end
end

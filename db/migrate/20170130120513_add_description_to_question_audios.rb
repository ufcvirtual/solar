class AddDescriptionToQuestionAudios < ActiveRecord::Migration[5.0]
  def change
  	add_column :question_audios, :description, :string
  end
end

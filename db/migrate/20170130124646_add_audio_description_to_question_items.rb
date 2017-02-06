class AddAudioDescriptionToQuestionItems < ActiveRecord::Migration
  def change
  	add_column :question_items, :audio_description, :string
  end
end

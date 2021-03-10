class AddAudioDescritionToQuestionAudios < ActiveRecord::Migration[5.1]
  def change
  	add_column :question_audios, :audio_description, :text
  end
end

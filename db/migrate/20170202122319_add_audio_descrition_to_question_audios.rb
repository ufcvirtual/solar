class AddAudioDescritionToQuestionAudios < ActiveRecord::Migration
  def change
  	add_column :question_audios, :audio_description, :text
  end
end

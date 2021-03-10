class AddColumFileAudioToQuestionItem < ActiveRecord::Migration[5.1]
  def change
  	add_attachment :question_items, :item_audio
  end
end

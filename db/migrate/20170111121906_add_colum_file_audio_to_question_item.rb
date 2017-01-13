class AddColumFileAudioToQuestionItem < ActiveRecord::Migration
  def change
  	add_attachment :question_items, :item_audio
  end
end

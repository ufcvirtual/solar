class AddDescriptionToQuestionAudios < ActiveRecord::Migration
  def change
  	add_column :question_audios, :description, :string
  end
end

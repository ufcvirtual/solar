class CreateDiscussionEnunciationFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :discussion_enunciation_files do |t|
      t.references :discussion

      t.timestamps
    end
    #add_index :discussion_enunciation_files, :discussion_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
  end
end

class CreateDiscussionEnunciationFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :discussion_enunciation_files do |t|
      t.references :discussion

      t.timestamps
    end
    #add_index :discussion_enunciation_files, :discussion_id
  end
end

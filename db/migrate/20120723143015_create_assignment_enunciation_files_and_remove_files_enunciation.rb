class CreateAssignmentEnunciationFilesAndRemoveFilesEnunciation < ActiveRecord::Migration
  def up
  	drop_table :files_enunciations

  	create_table :assignment_enunciation_files do |t|
      t.integer :assignment_id, :null => false
      t.string :attachment_file_name, :limit => 255, :null => false
      t.string :attachment_content_type, :limit => 45
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
    end

    add_foreign_key(:assignment_enunciation_files, :assignments)
  end

  def down
  	create_table :files_enunciations do |t|
      t.integer :assignment_id, :null => false
    end

    add_foreign_key(:files_enunciations, :assignments)

    drop_table :assignment_enunciation_files
  end
end
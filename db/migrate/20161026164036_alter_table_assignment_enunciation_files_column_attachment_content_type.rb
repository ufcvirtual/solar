class AlterTableAssignmentEnunciationFilesColumnAttachmentContentType < ActiveRecord::Migration
  def up
  	change_column :assignment_enunciation_files, :attachment_content_type, :string, :limit => 255
  end

  def down
  	change_column :assignment_enunciation_files, :attachment_content_type, :string, :limit => 45
  end
end

class AddAttachmentAttachmentToDiscussionEnunciationFiles < ActiveRecord::Migration
  def self.up
    change_table :discussion_enunciation_files do |t|
      t.attachment :attachment
    end
  end

  def self.down
    drop_attached_file :discussion_enunciation_files, :attachment
  end
end

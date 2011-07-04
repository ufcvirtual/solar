class CreateCommentFiles < ActiveRecord::Migration
  def self.up
    create_table :comment_files do |t|
      t.integer :assignment_comment_id, :null => false
      t.string :attachment_file_name, :limit => 255, :null => false
      t.string :attachment_content_type, :limit => 45
      t.integer :attachment_file_size
      t.datetime :attachment_update_at
    end
  end

  def self.down
    drop_table :comment_files
  end
end

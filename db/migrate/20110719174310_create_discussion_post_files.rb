class CreateDiscussionPostFiles < ActiveRecord::Migration
  def self.up
    create_table :discussion_post_files do |t|
      t.integer :discussion_post_id, :null => false
      t.string :attachment_file_name, :limit => 255, :null => false
      t.string :attachment_content_type, :limit => 45
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
    end

    add_foreign_key(:discussion_post_files, :discussion_posts)
  end

  def self.down
    drop_table :discussion_post_files
  end
end

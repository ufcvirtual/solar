class CreatePublicFiles < ActiveRecord::Migration
  def self.up
    create_table :public_files do |t|
      t.integer :allocation_tag_id,         :null => false
      t.integer :user_id,                   :null => false
      t.string :attachment_file_name,       :limit => 255, :null => false
      t.string :attachment_content_type,    :limit => 45
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
    end

    add_foreign_key(:public_files, :allocation_tags)
    add_foreign_key(:public_files, :users)
  end

  def self.down
    drop_table :public_files
  end
end

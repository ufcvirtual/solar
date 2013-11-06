class CreateSupportMaterialFiles < ActiveRecord::Migration
  def self.up
    create_table :support_material_files do |t|
      t.integer :allocation_tag_id,         :null => false
      t.string :attachment_file_name,       :limit => 255, :null => false
      t.string :attachment_content_type,    :limit => 255
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.string :folder,                     :limit => 255
    end

    add_foreign_key(:support_material_files, :allocation_tags)
  end

  def self.down
    drop_table :support_material_files
  end
end

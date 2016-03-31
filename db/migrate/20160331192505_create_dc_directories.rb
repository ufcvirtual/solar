class CreateDcDirectories < ActiveRecord::Migration
  def change
    create_table :dc_directories do |t|
    	t.references :allocation_tag, null: false
    	t.integer :directory_id, null: false
      t.timestamps

      t.foreign_key :allocation_tags, column: 'allocation_tag_id'
    end
    add_index :dc_directories, :directory_id 
  end
end

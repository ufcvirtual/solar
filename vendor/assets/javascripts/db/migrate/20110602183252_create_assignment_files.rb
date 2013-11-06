class CreateAssignmentFiles < ActiveRecord::Migration
  def self.up
    create_table :assignment_files do |t|
      t.integer :send_assignment_id, :null => false
      t.string :attachment_file_name, :limit => 255, :null => false
      t.string :attachment_content_type, :limit => 45
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
    end

    add_foreign_key(:assignment_files, :send_assignments)
  end

  def self.down
    drop_table :assignment_files
  end
end

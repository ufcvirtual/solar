class CreateFilesPublics < ActiveRecord::Migration
  def self.up
    create_table :files_publics do |t|
      t.integer :allocation_tag_id, :null => false
      t.integer :user_id, :null => false
    end
  end

  def self.down
    drop_table :files_publics
  end
end

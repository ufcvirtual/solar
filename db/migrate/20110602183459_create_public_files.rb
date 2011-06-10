class CreatePublicFiles < ActiveRecord::Migration
  def self.up
    create_table :public_files do |t|
      t.integer :allocation_tag_id, :null => false
      t.integer :user_id, :null => false
    end
  end

  def self.down
    drop_table :public_files
  end
end

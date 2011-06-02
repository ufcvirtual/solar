class CreateAssignment < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :allocation_tag_id, :null => false
      t.text :enunciation
    end
  end

  def self.down
    drop_table :assignments
  end
end

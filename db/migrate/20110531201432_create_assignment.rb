class CreateAssignment < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :allocation_tag_id, :null => false
      t.string :name, :limit => 100, :null => false
      t.text :enunciation
      t.date :initial_date, :null => false
      t.date :final_date, :null => false
    end
  end

  def self.down
    drop_table :assignments
  end
end

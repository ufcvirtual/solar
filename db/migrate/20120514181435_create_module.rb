class CreateModule < ActiveRecord::Migration
  def self.up
    create_table :lesson_modules do |t|
      t.integer :allocation_tag_id, :null => false
      t.string  :name, :limit => 100, :null => false
      t.string  :description, :limit => 255
    end
  end

  def self.down
    drop_table   :lesson_modules
  end
end

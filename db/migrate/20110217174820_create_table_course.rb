class CreateTableCourse < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.string :name, :null => false
      t.string :code
      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end
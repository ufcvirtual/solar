class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table "courses" do |t|
      t.string   "name",       :null => false
      t.string   "code"
    end
  end

  def self.down
    drop_table "courses"
  end
end

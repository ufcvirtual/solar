class CreateOffers < ActiveRecord::Migration
  def self.up
    create_table "offers" do |t|
      t.integer  "curriculum_unit_id"
      t.integer  "course_id"
      t.string   "semester"
      t.date     "start", :null => false
      t.date     "end",   :null => false
    end
  end

  def self.down
    drop_table "offers"
  end
end

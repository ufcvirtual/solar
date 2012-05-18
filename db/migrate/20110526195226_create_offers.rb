class CreateOffers < ActiveRecord::Migration
  def self.up
    create_table "offers" do |t|
      t.integer  "curriculum_unit_id"
      t.integer  "course_id"
      t.string   "semester"
      t.date     "start", :null => false
      t.date     "end",   :null => false
    end

    add_foreign_key(:offers, :curriculum_units)
    add_foreign_key(:offers, :courses)
  end

  def self.down
    drop_table "offers"
  end
end

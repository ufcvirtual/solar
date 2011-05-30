class CreateEnrollments < ActiveRecord::Migration
  def self.up
    create_table "enrollments" do |t|
      t.integer  "offer_id"
      t.date     "start",      :null => false
      t.date     "end",        :null => false
    end
  end

  def self.down
    drop_table "enrollments"
  end
end

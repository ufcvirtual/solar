class CreateTableOffer < ActiveRecord::Migration
  def self.up
    create_table :offer do |t|
      t.integer :curriculum_unit_id,  :null => false
      t.integer :course_id
      t.string  :period
      t.date    :start,               :null => false
      t.date    :end,                 :null => false
      t.timestamps
    end

    add_index :offer, ["curriculum_unit_id"], :name => "index_offer_on_curriculum_unit"
    add_index :offer, ["course_id"],          :name => "index_offer_on_course"
  end

  def self.down
    drop_table :offer
  end
end

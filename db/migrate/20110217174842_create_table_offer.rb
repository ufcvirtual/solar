class CreateTableOffer < ActiveRecord::Migration
  def self.up
    create_table :offers do |t|
      t.references :curriculum_unities
      t.references :courses
      t.string  :semester
      t.date    :start,               :null => false
      t.date    :end,                 :null => false
      t.timestamps
    end
  end

  def self.down    
    drop_table :offers
  end
end

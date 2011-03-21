class CreateTableAllocationTag < ActiveRecord::Migration
  def self.up

    create_table :allocation_tags do |t|
      t.references :groups
      t.references :offers
      t.references :curriculum_units
      t.references :courses
    end

  end

  def self.down

    drop_table :allocation_tags

  end
end

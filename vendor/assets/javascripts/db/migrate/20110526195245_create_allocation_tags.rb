class CreateAllocationTags < ActiveRecord::Migration
  def self.up
    create_table "allocation_tags" do |t|
      t.integer "group_id"
      t.integer "offer_id"
      t.integer "curriculum_unit_id"
      t.integer "course_id"
    end

    add_foreign_key(:allocation_tags, :groups)
    add_foreign_key(:allocation_tags, :offers)
    add_foreign_key(:allocation_tags, :curriculum_units)
    add_foreign_key(:allocation_tags, :courses)
  end

  def self.down
    drop_table "allocation_tags"
  end
end

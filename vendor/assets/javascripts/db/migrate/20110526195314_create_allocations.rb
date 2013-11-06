class CreateAllocations < ActiveRecord::Migration
  def self.up
    create_table "allocations" do |t|
      t.integer  "user_id", :null => false
      t.integer  "allocation_tag_id"
      t.integer  "profile_id", :null => false
      t.integer  "status", :default => 0
    end

    add_foreign_key(:allocations, :users)
    add_foreign_key(:allocations, :allocation_tags)
    add_foreign_key(:allocations, :profiles)
  end

  def self.down
    drop_table "allocations"
  end
end

class CreateAllocations < ActiveRecord::Migration
  def self.up
    create_table "allocations" do |t|
      t.integer  "user_id"
      t.integer  "allocation_tag_id"
      t.integer  "profile_id"
      t.integer  "status", :default => 0
    end
  end

  def self.down
    drop_table "allocations"
  end
end

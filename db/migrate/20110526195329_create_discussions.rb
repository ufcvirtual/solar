class CreateDiscussions < ActiveRecord::Migration
  def self.up
    create_table "discussions" do |t|
      t.string  "name", :limit => 120
      t.string  "description", :limit => 600
      t.integer "allocation_tag_id", :null => false
      t.integer "schedule_id", :null => false
      t.date    "start"
      t.date    "end"
    end

    add_foreign_key(:discussions, :allocation_tags)
    add_foreign_key(:discussions, :schedules)
  end

  def self.down
    drop_table "discussions"
  end
end

class CreateDiscussions < ActiveRecord::Migration
  def self.up
    create_table "discussions" do |t|
      t.string  "name",               :limit => 120
      t.date    "start"
      t.date    "end"
      t.string  "description",        :limit => 600
      t.integer "allocation_tag_id"
      
      t.integer "schedule_id"
      
    end
  end

  def self.down
    drop_table "discussions"
  end
end

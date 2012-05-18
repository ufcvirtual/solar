class CreateLessons < ActiveRecord::Migration
  def self.up
    create_table "lessons" do |t|
      t.integer  "allocation_tag_id"
      t.integer  "user_id"
      t.integer "schedule_id"
      t.string   "name",                                 :null => false
      t.string   "description"
      t.string   "address",                              :null => false
      t.integer  "type_lesson",                          :null => false
      t.boolean  "privacy",            :default => true, :null => false
      t.integer  "order",                                :null => false
      t.integer  "status",             :default => 0,    :null => false
      t.date     "start",                                :null => false
      t.date     "end",                                  :null => false
    end

    add_foreign_key(:lessons, :allocation_tags)
    add_foreign_key(:lessons, :users)
    add_foreign_key(:lessons, :schedules)
  end

  def self.down
    drop_table "lessons"
  end
end

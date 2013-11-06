class CreateAssignment < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :allocation_tag_id, :null => false
      t.integer :schedule_id
      t.string :name, :limit => 100, :null => false
      t.text :enunciation
      t.datetime :start_date, :null => false
      t.datetime :end_date, :null => false
    end

    add_foreign_key(:assignments, :allocation_tags)
    add_foreign_key(:assignments, :schedules)
  end

  def self.down
    drop_table :assignments
  end
end

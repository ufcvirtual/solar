class AddSchemaOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :schedule_id, :integer, false: true
    add_foreign_key(:offers, :schedules)
  end

  def down
  	remove_column :offers, :schedule_id
  end
end

class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table "groups" do |t|
      t.integer  "offer_id", :null => false
      t.string   "code"
      t.boolean  "status", :default => true
    end

    add_foreign_key(:groups, :offers)
  end

  def self.down
    drop_table "groups"
  end
end

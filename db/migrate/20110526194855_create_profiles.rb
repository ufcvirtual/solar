class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table "profiles" do |t|
      t.string  "name",              :null => false
      t.boolean "student",           :default => false
      t.boolean "class_responsible", :default => false
      t.boolean "status",            :default => true
    end
  end

  def self.down
    drop_table "profiles"
  end
end

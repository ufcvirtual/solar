class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table "profiles" do |t|
      t.string  "name",              :null => false
      t.boolean "student",           :default => false
      t.integer "types",              :default => 0
      t.boolean "status",            :default => true
    end
  end

  def self.down
    drop_table "profiles"
  end
end
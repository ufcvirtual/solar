class CreateProfiles < ActiveRecord::Migration[5.0]
  def self.up
    create_table "profiles" do |t|
      t.string  "name",              :null => false
      t.integer "types",              :default => 0
      t.boolean "status",            :default => true
    end
  end

  def self.down
    drop_table "profiles"
  end
end
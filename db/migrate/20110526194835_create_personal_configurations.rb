class CreatePersonalConfigurations < ActiveRecord::Migration
  def self.up
    create_table "personal_configurations" do |t|
      t.integer  "user_id",          :null => false
      t.string   "theme"
      t.string   "mysolar_portlets"
      t.string   "default_locale"
    end

    add_index "personal_configurations", ["user_id"], :name => "index_user_on_personal_configuration", :unique => true
  end

  def self.down
    drop_table "personal_configurations"
  end
end

class CreatePersonalConfigurations < ActiveRecord::Migration
  def self.up
    create_table "personal_configurations" do |t|
      t.integer  "user_id", :null => false
      t.string   "theme"
      t.string   "default_locale"
    end

    add_foreign_key(:personal_configurations, :users)
  end

  def self.down
    drop_table "personal_configurations"
  end
end

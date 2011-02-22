class CreatePersonalConfigurations < ActiveRecord::Migration
  def self.up
    create_table :personal_configurations do |t|
      t.string    :theme,               :null => true
      t.string    :mysolar_portlets,    :null => true
      t.string    :default_locale,      :null => true
      t.integer   :user_id,              :null => false
      t.timestamps
    end

    add_index :personal_configurations, ["user_id"], :name => "index_user_on_personal_configuration", :unique => true
  end

  def self.down
    drop_table :personal_configurations
  end
end

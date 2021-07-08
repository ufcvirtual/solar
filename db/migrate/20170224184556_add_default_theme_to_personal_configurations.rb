class AddDefaultThemeToPersonalConfigurations < ActiveRecord::Migration[5.1]
  def self.up
  	change_column :personal_configurations, :theme, :string, :default => "blue"
  	PersonalConfiguration.update_all(theme: "blue")
  end

  def self.down
  	change_column :personal_configurations, :theme, :string
  end
end

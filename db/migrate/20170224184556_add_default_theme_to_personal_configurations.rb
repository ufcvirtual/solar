class AddDefaultThemeToPersonalConfigurations < ActiveRecord::Migration
  def self.up
  	change_column :personal_configurations, :theme, :string, :default => "theme_blue"
  	PersonalConfiguration.update_all(theme: "theme_blue")
  end

  def self.down
  end
end

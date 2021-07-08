class AddMessageExamPostToPersonalConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :personal_configurations, :message, :boolean, default: true, null: false 
    add_column :personal_configurations, :exam, :boolean, default: true, null: false 
    add_column :personal_configurations, :post, :boolean, default: true, null: false 
  end
end

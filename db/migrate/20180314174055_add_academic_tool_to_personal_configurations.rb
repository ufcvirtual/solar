class AddAcademicToolToPersonalConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :personal_configurations, :academic_tool, :boolean, default: true, null: false
  end
end

class AlterTableDiscussionsDescriptionAsText < ActiveRecord::Migration[5.1]
  def self.up
  	change_column :discussions, :description, :text
  end

  def self.down
  	change_column :discussions, :description, :string, :limit => 600
  end
end

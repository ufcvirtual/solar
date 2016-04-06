class AddDigitalClassDirectoryIdToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :digital_class_directory_id, :integer, index: true
  end
end

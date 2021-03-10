class AddDigitalClassDirectoryIdToGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :digital_class_directory_id, :integer, index: true
  end
end

class AddShareGroupsColumnToWebconferences < ActiveRecord::Migration[5.1]
  def change
    add_column :webconferences, :shared_between_groups, :boolean, default: false
  end
end

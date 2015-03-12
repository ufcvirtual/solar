class AddShareGroupsColumnToWebconferences < ActiveRecord::Migration
  def change
    add_column :webconferences, :shared_between_groups, :boolean, default: false
  end
end

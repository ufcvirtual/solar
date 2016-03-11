class AddColumnPublicFilesIdToLogNavigationSubs < ActiveRecord::Migration
  def change
    add_column :log_navigation_subs, :public_files_id, :integer
  end
end

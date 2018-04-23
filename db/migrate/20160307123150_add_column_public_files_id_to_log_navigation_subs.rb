class AddColumnPublicFilesIdToLogNavigationSubs < ActiveRecord::Migration[5.0]
  def change
    add_column :log_navigation_subs, :public_files_id, :integer
  end
end

class AddColumnBibliographiesIdToLogNavigationSub < ActiveRecord::Migration
  def change
    add_column :log_navigation_subs, :bibliographie_id, :integer
  end
end

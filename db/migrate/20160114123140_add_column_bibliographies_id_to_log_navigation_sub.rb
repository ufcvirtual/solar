class AddColumnBibliographiesIdToLogNavigationSub < ActiveRecord::Migration[5.1]
  def change
    add_column :log_navigation_subs, :bibliographie_id, :integer
  end
end

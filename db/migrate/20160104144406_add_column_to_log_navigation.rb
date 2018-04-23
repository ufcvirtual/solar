class AddColumnToLogNavigation < ActiveRecord::Migration[5.0]
  def change
    add_column :log_navigations, :allocation_tag_id, :integer
    add_column :log_navigations, :offers_id, :integer
  end
end

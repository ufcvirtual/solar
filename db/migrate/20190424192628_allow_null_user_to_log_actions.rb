class AllowNullUserToLogActions < ActiveRecord::Migration
  def change
    change_column :log_actions, :user_id, :integer, null: true
  end
end

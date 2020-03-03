class AllowNullUserToLogActions < ActiveRecord::Migration[5.0]
  def change
    change_column :log_actions, :user_id, :integer, null: true
  end
end

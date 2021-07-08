class RemoveIndexFromEmail < ActiveRecord::Migration[5.1]
  def up
    remove_index(:users, name: 'index_users_on_email') if index_exists?(:users, :email)
    change_column :users, :email, :string, size: 200, null: true, default: nil
  end

  def down
  end
end

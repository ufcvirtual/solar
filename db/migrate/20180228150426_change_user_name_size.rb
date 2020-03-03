class ChangeUserNameSize < ActiveRecord::Migration[5.0]
  def up
    change_column :users, :name, :string, limit: 200
  end
end

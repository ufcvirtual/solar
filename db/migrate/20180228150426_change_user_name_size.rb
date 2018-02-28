class ChangeUserNameSize < ActiveRecord::Migration
  def up
    change_column :users, :name, :string, limit: 200
  end
end

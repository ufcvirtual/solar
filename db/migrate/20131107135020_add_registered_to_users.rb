class AddRegisteredToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :registered, :boolean, :default => false
  end
end

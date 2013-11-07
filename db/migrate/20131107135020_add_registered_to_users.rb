class AddRegisteredToUsers < ActiveRecord::Migration
  def change
    add_column :users, :registered, :boolean, :default => false
  end
end

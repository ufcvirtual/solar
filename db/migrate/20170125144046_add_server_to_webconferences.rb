class AddServerToWebconferences < ActiveRecord::Migration
  def change
    add_column :webconferences, :server, :integer
    add_index :webconferences, :server
  end
end

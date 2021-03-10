class AddServerToWebconferences < ActiveRecord::Migration[5.1]
  def change
    add_column :webconferences, :server, :integer
    add_index :webconferences, :server
  end
end

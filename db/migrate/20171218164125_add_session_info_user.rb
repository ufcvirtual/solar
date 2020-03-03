class AddSessionInfoUser < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :session_token, :string
  end
end

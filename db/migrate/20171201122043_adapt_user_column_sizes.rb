class AdaptUserColumnSizes < ActiveRecord::Migration[5.0]
  def up
  	change_column :users, :email, :string, limit: 200
  	change_column :users, :address, :string, limit: 150
  	change_column :users, :cell_phone, :string, limit: 100
  	change_column :users, :telephone, :string, limit: 50
  end
end

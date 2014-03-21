class UserChangeAddressType < ActiveRecord::Migration
  def up
    change_column :users, :address_number, :string, limit: 10
  end

  def down
    # nao pode transformar string em integer
  end
end

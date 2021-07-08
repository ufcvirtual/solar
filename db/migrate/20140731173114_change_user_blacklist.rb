class ChangeUserBlacklist < ActiveRecord::Migration[5.1]
  def up
  	change_column :user_blacklist, :cpf, :string, null: false
  end

  def down
  	change_column :user_blacklist, :cpf, :string, null: true
  end
end

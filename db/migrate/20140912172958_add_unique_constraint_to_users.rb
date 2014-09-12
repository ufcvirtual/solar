class AddUniqueConstraintToUsers < ActiveRecord::Migration
  def change
    add_index :users, [:cpf], unique: true
  end
end

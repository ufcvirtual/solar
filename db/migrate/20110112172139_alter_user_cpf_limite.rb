class AlterUserCpfLimite < ActiveRecord::Migration
  def self.up
    change_column :users, :cpf, :string, :limit => 14
  end

  def self.down
    change_column :users, :cpf, :string, :limit => 11
  end
end

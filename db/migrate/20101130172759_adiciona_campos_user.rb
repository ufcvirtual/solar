class AdicionaCamposUser < ActiveRecord::Migration
  def self.up
    add_column :users, :nome,  :string, :limit => 100
    add_column :users, :nick,  :string, :limit => 35
    add_column :users, :dtnascimento,  :datetime
    add_column :users, :matricula, :string, :limit => 20
    add_column :users, :cpf,  :string, :limit => 11
    add_column :users, :sexo, :string, :limit => 1
    add_column :users, :status, :bit
  end

  def self.down
    remove_column :users, :nome
    remove_column :users, :nick
    remove_column :users, :dtnascimento
    remove_column :users, :matricula
    remove_column :users, :cpf
    remove_column :users, :sexo
    remove_column :users, :status
  end
end

class CreateUsuarios < ActiveRecord::Migration
  def self.up
    create_table :usuarios do |t|
	  t.string :nome, :limit => 100
	  t.string :login, :limit => 15
	  t.string :cpf, :limit => 11
	  t.string :senha, :limit => 40
      t.timestamps
    end
  end

  def self.down
    drop_table :usuarios
  end
end

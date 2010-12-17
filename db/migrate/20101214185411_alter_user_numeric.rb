class AlterUserNumeric < ActiveRecord::Migration
  def self.up
	remove_column :users, :cpf
	add_column :users, :cpf, :Bigint, :limit => 11
	change_column :users, :telephone, :string, :limit => 20
	change_column :users, :cell_phone, :string, :limit => 20
  end

  def self.down
	remove_column :users, :cpf
	add_column :users, :cpf, :string, :limit => 11
	change_column :users, :telephone,  :integer
	change_column :users, :cell_phone,  :integer
  end
end

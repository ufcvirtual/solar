class AlterUsers < ActiveRecord::Migration
  def self.up
	rename_column :users, :nome, :name
	rename_column :users, :dtnascimento, :birthdate
	rename_column :users, :matricula, :enrollment_code
	rename_column :users, :sexo, :sex

	add_column :users, :special_needs,  :string, :limit => 50
	add_column :users, :address,  :string, :limit => 100
	add_column :users, :address_number,  :integer
	add_column :users, :address_complement,  :string, :limit => 50
	add_column :users, :address_neighborhood,  :string, :limit => 50
	add_column :users, :zipcode,  :integer
	add_column :users, :country,  :string, :limit => 100
	add_column :users, :state,  :string, :limit => 100
	add_column :users, :city,  :string, :limit => 100
	add_column :users, :telephone,  :integer
	add_column :users, :cell_phone,  :integer
	add_column :users, :institution,  :string, :limit => 120
  end

  def self.down
	rename_column :users, :name, :nome
	rename_column :users, :birthdate, :dtnascimento
	rename_column :users, :enrollment_code, :matricula
	rename_column :users, :sex, :sexo

	remove_column :users, :special_needs
	remove_column :users, :address
	remove_column :users, :address_number
	remove_column :users, :address_complement
	remove_column :users, :address_neighborhood
	remove_column :users, :zipcode
	remove_column :users, :country
	remove_column :users, :state
	remove_column :users, :city
	remove_column :users, :telephone
	remove_column :users, :cell_phone
	remove_column :users, :institution
  end
end


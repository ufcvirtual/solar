class AlterUserData < ActiveRecord::Migration
  def self.up
	change_column :users, :birthdate, :date
	remove_column :users, :sex
	add_column :users, :sex, :boolean
  end

  def self.down
	change_column :users, :birthdate, :datetime
	remove_column :users, :sex
	add_column :users, :sex, :string, :limit => 1
  end
end

class AlterCepToString < ActiveRecord::Migration
  def self.up
    change_column :users,:zipcode,:string, :limit => 11
  end

  def self.down
    change_column :users, :zipcode,  :integer
  end
end

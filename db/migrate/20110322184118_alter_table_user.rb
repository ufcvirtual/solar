class AlterTableUser < ActiveRecord::Migration
  def self.up
  	rename_column :users, :sex, :gender
  end

  def self.down
  	rename_column :users, :gender, :sex
  end
end

class AddAlternateEmailUser < ActiveRecord::Migration
  def self.up
    add_column :users,  :alternate_email, :string
  end

  def self.down
    remove_column :users, :alternate_email
  end
end

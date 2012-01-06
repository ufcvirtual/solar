class AddDeviseToUsers < ActiveRecord::Migration
  def self.up
    change_table(:users) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.encryptable
      t.token_authenticatable
      # t.confirmable
    end

  end

  def self.down

    change_table(:users) do |t|
      t.remove database_authenticatable 
      t.remove recoverable
      t.remove encryptable
      t.remove token_authenticatable
    end

  end
end

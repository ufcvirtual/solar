class AddDeviseToUsers < ActiveRecord::Migration
  def self.up
    change_table(:users) do |t|
#      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
#      t.trackable

      # t.encryptable
      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable


      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps
    end

#    add_index :users, :email,                :unique => true
#    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true

    rename_column :users, :crypted_password, :encrypted_password
    rename_column :users, :login, :username
  end

  def self.down

    change_table(:users) do |t|
      t.remove recoverable
      t.remove rememberable
    end

    rename_column :users, :encrypted_password, :crypted_password
    rename_column :users, :username, :login
  end
end

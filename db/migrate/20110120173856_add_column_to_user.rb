class AddColumnToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :bio,  :text
    add_column :users, :interests,:text
    add_column :users, :music,:text
    add_column :users, :movies,:text
    add_column :users, :books,:text
    add_column :users, :phrase,:text
    add_column :users, :site,:text
  end

  def self.down
    remove_column :users,:bio
    remove_column :users,:interests
    remove_column :users,:music
    remove_column :users,:movies
    remove_column :users,:books
    remove_column :users,:phrase
    remove_column :users,:site

    end
end

class AddSpecificUserToComments < ActiveRecord::Migration
  def up
  	add_column :comments, :specific_user_id, :integer, null: true
  end

  def down
  	remove_column :comments, :specific_user_id, :integer
  end
end

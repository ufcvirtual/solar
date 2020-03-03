class AddSpecificUserToComments < ActiveRecord::Migration[5.0]
  def up
  	add_column :comments, :specific_user_id, :integer, null: true
  end

  def down
  	remove_column :comments, :specific_user_id, :integer
  end
end

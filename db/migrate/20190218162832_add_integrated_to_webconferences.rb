class AddIntegratedToWebconferences < ActiveRecord::Migration[5.0]
  def up
  	add_column :webconferences, :integrated, :boolean, default: false
  	change_column :webconferences, :user_id, :integer, null: true
  end

  def down
  	remove_column :webconferences, :integrated, :boolean
  	# change_column :webconferences, :user_id, :integer, null: false
  end
end

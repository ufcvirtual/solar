class RemoveNameFromQuestion < ActiveRecord::Migration
  def up
  	remove_column :questions, :name
  end

  def down
  	add_column :questions, :name, :string, null: false
  end
end

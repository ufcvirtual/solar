class RemoveLinkFromMenu < ActiveRecord::Migration[5.0]
  def up
    remove_column :menus, :link
  end

  def down
    add_column :menus, :link, :string
  end
end

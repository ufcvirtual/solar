class AddTitleToSupportMaterialFile < ActiveRecord::Migration
  def change
    add_column :support_material_files, :title, :string
  end
end

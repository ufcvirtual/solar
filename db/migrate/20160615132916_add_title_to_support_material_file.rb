class AddTitleToSupportMaterialFile < ActiveRecord::Migration[5.0]
  def change
    add_column :support_material_files, :title, :string
  end
end

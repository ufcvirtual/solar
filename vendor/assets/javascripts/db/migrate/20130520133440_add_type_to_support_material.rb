class AddTypeToSupportMaterial < ActiveRecord::Migration
  def up
    change_table :support_material_files do |t|
      t.integer :material_type, null: false, default: 0 # 0: file, 1: link
    end

    SupportMaterialFile.all.each do |s|
      s.update_attributes(material_type: (s.url.nil? ? 0 : 1))
    end
  end

  def down
    remove_column :support_material_files, :material_type
  end
end

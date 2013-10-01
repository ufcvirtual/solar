class TransferDataOfSupportMaterialFileToAcademicAllocation < ActiveRecord::Migration
  def up
    SupportMaterialFile.all.each do |support_material|
      AcademicAllocation.create(allocation_tag_id: support_material.allocation_tag_id, academic_tool_id: support_material.id, academic_tool_type: 'SupportMaterialFile')
    end

    change_table :support_material_files do |t|
      t.remove :allocation_tag_id
    end
  end

  def down
    change_table :support_material_files do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
    end

    AcademicAllocation.where(academic_tool_type: 'SupportMaterialFile').each do |academic_allocation|
      SupportMaterialFile.find(academic_allocation.academic_tool_id).update_attribute(:allocation_tag_id, academic_allocation.allocation_tag_id)
      academic_allocation.destroy
    end
  end
end

class TransferDataOfDiscussionToAcademicAllocation < ActiveRecord::Migration
  def up
    Discussion.all.each do |discussion|
      AcademicAllocation.create(allocation_tag_id: discussion.allocation_tag_id, academic_tool_id: discussion.id, academic_tool_type: 'Discussion')
    end

    change_table :discussions do |t|
      t.remove :allocation_tag_id
    end
  end

  def down
    change_table :discussions do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
    end

    AcademicAllocation.where(academic_tool_type: 'Discussion').each do |academic_allocation|
      Discussion.find(academic_allocation.academic_tool_id).update_attribute(:allocation_tag_id, academic_allocation.allocation_tag_id)
      academic_allocation.destroy
    end
  end
end
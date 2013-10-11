class TransferDataOfLessonModuleToAcademicAllocation < ActiveRecord::Migration
  def up
    lesson_modules = LessonModule.all
   
    lesson_modules.each do |lesson_module|
      academic_allocation = AcademicAllocation.create(allocation_tag_id: lesson_module.allocation_tag_id, academic_tool_id: lesson_module.id, academic_tool_type: 'LessonModule')
    end

    change_table :lesson_modules do |t|
      t.remove :allocation_tag_id
    end  

  end

  def down
    change_table :lesson_modules do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
    end

    academic_allocations = AcademicAllocation.where(academic_tool_type: 'LessonModule')

    academic_allocations.each do |academic_allocation|
      lesson_module = LessonModule.find(academic_allocation.academic_tool_id)
      lesson_module.update_attributes(allocation_tag_id: academic_allocation.allocation_tag_id)
    end  

    academic_allocations.each do |academic_allocation|
      academic_allocation.destroy
    end 
      
  end
end
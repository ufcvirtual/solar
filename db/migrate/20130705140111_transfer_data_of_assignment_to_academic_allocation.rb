class TransferDataOfAssignmentToAcademicAllocation < ActiveRecord::Migration
  def up
    
    rename_table :educational_tools, :academic_allocations

    change_table :academic_allocations do |t|
      t.rename :educational_tool_id, :academic_tool_id
      t.rename :educational_tool_type, :academic_tool_type
    end

    change_table :sent_assignments do |t|
      t.references :academic_allocation
      t.foreign_key :academic_allocations
    end

    assignments = Assignment.all
   
    assignments.each do |assignment|
      # O Model EducationalTool ainda nao existe, tem q criar antes de chamar a linha seguinte
      academic_allocation = AcademicAllocation.create(allocation_tag_id: assignment.allocation_tag_id, academic_tool_id: assignment.id, academic_tool_type: 'Assignment')

      SentAssignment.where(assignment_id: assignment.id).each do |sent_assigment|
        sent_assigment.update_attributes(academic_allocation_id: academic_allocation.id)
      end
    end


    change_table :sent_assignments do |t|
      t.remove_index column: [:assignment_id, :user_id]
      t.remove :assignment_id
      t.index [:academic_allocation_id, :user_id], unique: true
    end

    change_table :assignments do |t|
      t.remove :allocation_tag_id
    end

  end

  def down   
    change_table :assignments do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
    end

    change_table :sent_assignments do |t|
      t.remove_index column: [:academic_allocation_id, :user_id]
      t.references :assignment
      t.foreign_key :assignments
      t.index [:assignment_id, :user_id], unique: true
    end    

    sent_assignments = SentAssignment.all

    sent_assignments.each do |sent_assignment|
      sent_assigment.update_attributes(assignment_id: sent_assigment.academic_allocation.academic_tool_id)
    end  

    academic_allocations = AcademicTool.where(academic_tool_type: 'Assignment')

    academic_allocations.each do |academic_allocation|
      assignment = Assignment.find(academic_allocation.academic_tool_id)
      assignment.update_attributes(allocation_tag_id: academic_allocation.allocation_tag_id)
    end 

    change_table :sent_assignments do |t|
      t.remove_column :academic_allocation_id
    end

    change_table :academic_allocations do |t|
      t.rename :academic_tool_id, :educational_tool_id 
      t.rename :academic_tool_type, :educational_tool_type 
    end

    rename_table :academic_allocations, :educational_tools

  end

end

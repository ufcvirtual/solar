class TransferDataOfAssignmentToAcademicAllocation < ActiveRecord::Migration
  def up
    
    drop_table :educational_tools

    create_table :academic_allocations do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
      t.references :academic_tool, :polymorphic => true
    end

    change_table :sent_assignments do |t|
      t.references :academic_allocation
      t.foreign_key :academic_allocations
    end

    assignments = Assignment.all
   
    assignments.each do |assignment|
      # O Model EducationalTool ainda nao existe, tem q criar antes de chamar a linha seguinte
      academic_allocation = AcademicAllocation.create(allocation_tag_id: assignment.allocation_tag_id, academic_tool_id: assignment.id, academic_tool_type: 'Assignment')

      SentAssignment.where(assignment_id: assignment.id).each do |sent_assignment|
        sent_assignment.update_attributes(academic_allocation_id: academic_allocation.id)
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

    #Para funcionar a reversão é necessário alterar os relacionamentos do model adequadamente.
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
      sent_assignment.update_attributes(assignment_id: sent_assignment.academic_allocation.academic_tool_id)
    end  

    academic_allocations = AcademicAllocation.where(academic_tool_type: 'Assignment')

    academic_allocations.each do |academic_allocation|
      assignment = Assignment.find(academic_allocation.academic_tool_id)
      assignment.update_attributes(allocation_tag_id: academic_allocation.allocation_tag_id)
    end 

    change_table :sent_assignments do |t|
      t.remove :academic_allocation_id
    end

    drop_table :academic_allocations

    create_table :educational_tools do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
      t.references :educational_tool, :polymorphic => true
    end    
    
  end

end

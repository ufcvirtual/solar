class AlterGroupAssignment < ActiveRecord::Migration
  def up

    change_table :group_assignments do |t|
      t.references :academic_allocation
      t.foreign_key :academic_allocations
    end

    group_assignments = GroupAssignment.all

    group_assignments.each do |group_assignment|
      academic_allocation_id = AcademicAllocation.select(:id).where(academic_tool_id: group_assignment.assignment_id).first.id
      group_assignment.update_attributes(academic_allocation_id: academic_allocation_id)
    end

    change_table :group_assignments do |t|
      t.remove :assignment_id
    end

  end
  

  def down
    change_table :group_assignments do |t|
      t.references :assignment
      t.foreign_key :assignments
    end

    group_assignments = GroupAssignment.all

    # Volta ao estado original de um trabalho só pode ser associado com uma turma(PERCA de dados, caso um trabalho seja
    # associado a mais de uma turma)
    group_assignments.each do |group_assignment|
      academic_tool_id = AcademicAllocation.select(:academic_tool_id).where(id: group_assignment.academic_allocation_id).first.academic_tool_id
      group_assignment.update_attributes(assignment_id: academic_tool_id)
    end

    change_table :group_assignments do |t|
      t.remove :academic_allocation_id
    end

  end
end

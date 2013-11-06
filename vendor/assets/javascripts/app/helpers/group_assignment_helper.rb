module GroupAssignmentHelper

  ##
  # Retorna informações do grupo
  ##
  def info_assignment_group(group_assignment)
    evaluated           = (group_assignment.sent_assignment.nil? or group_assignment.sent_assignment.grade.nil?) ? false : true
    quantity_files_sent = (group_assignment.sent_assignment.nil? ? 0 : AssignmentFile.find_all_by_sent_assignment_id(group_assignment.sent_assignment.id).size) 
    can_remove          = (!evaluated and quantity_files_sent == 0 )
    error_message       = evaluated ? t(:already_evaluated, :scope => [:assignment, :group_assignments]) : nil
    error_message       = (quantity_files_sent == 0) ? error_message : t(:already_sent_files, :scope => [:assignment, :group_assignments]) 
    error_message       = t(:delete_error, :scope => [:assignment, :group_assignments]) + ", " + error_message.to_s unless error_message.nil?
    return {"evaluated" => evaluated, "can_remove" => can_remove, "quantity_files_sent" => quantity_files_sent, "error_message" => error_message}
  end

  ##        
  # Verifica se a atividade enviada já possui grupos e se alguma outra atividade já tem grupos criados
  ##          
  def verify_group_of_assignments(allocation_tag,assignment_id) 
    academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id,assignment_id, 'Assignment') 
    assignment_without_groups = GroupAssignment.find_all_by_academic_allocation_id(academic_allocation).empty?
    all_assignments = GroupAssignment.all_by_group_id(allocation_tag.group_id)
    all_assignments_id         = all_assignments.collect{|academic_allocation| academic_allocation["id"].to_i} unless all_assignments.empty?
    some_assignment_has_groups = !GroupAssignment.where(:academic_allocation_id => all_assignments_id).empty? unless all_assignments_id.nil?
    return (assignment_without_groups and some_assignment_has_groups)
  end
  
end
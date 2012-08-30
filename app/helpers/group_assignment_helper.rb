module GroupAssignmentHelper

  ##
  # Retorna informações do grupo
  ##
  def info_assignment_group(group_assignment)
    evaluated           = (group_assignment.send_assignment.nil? or group_assignment.send_assignment.grade.nil?) ? false : true
    quantity_files_sent = (group_assignment.send_assignment.nil? ? 0 : AssignmentFile.find_all_by_send_assignment_id(group_assignment.send_assignment.id).size) 
    can_remove          = (!evaluated and quantity_files_sent == 0 )
    error_message       = evaluated ? t(:already_evaluated, :scope => [:portfolio, :group_assignments]) : nil
    error_message       = (quantity_files_sent == 0) ? error_message : t(:already_sent_files, :scope => [:portfolio, :group_assignments]) 
    error_message       = t(:delete_error, :scope => [:portfolio, :group_assignments]) + ", " + error_message.to_s unless error_message.nil?
    return {"evaluated" => evaluated, "can_remove" => can_remove, "quantity_files_sent" => quantity_files_sent, "error_message" => error_message}
  end

  ##
  # Retorna os alunos sem grupo daquela atividade
  ##
  def no_group_students(assignment_id)
  	return(GroupAssignment.all_without_group(assignment_id))
  end

  ##        
  # Verifica se a atividade enviada já possui grupos e se alguma outra atividade já tem grupos criados
  ##          
  def verify_group_of_assignments(assignment_id) 
    assignment_without_groups = GroupAssignment.find_all_by_assignment_id(assignment_id).empty?
    all_assignments = GroupAssignment.all_by_group_id(Assignment.find(assignment_id).allocation_tag.group_id)
    all_assignments_id = all_assignments.collect{|assignment| assignment["id"].to_i} unless all_assignments.empty?
    some_assignment_has_groups = !GroupAssignment.where(:assignment_id => all_assignments_id).empty? unless all_assignments_id.nil?
    return (assignment_without_groups and some_assignment_has_groups)
  end
  
end
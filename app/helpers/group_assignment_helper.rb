module GroupAssignmentHelper
  
  ##
  # Retorna os grupos de determinada atividade (assignment).
  # Se for a edição de um grupo, há a necessidade de passar o valor do grupo que deve vir em primeiro lugar na lista. 
  # Por isso o campo "first_of_list"
  ##
  def group_assignments(assignment, first_of_list = nil)
    groups = []
    groups << GroupAssignment.find(first_of_list) unless first_of_list.nil?
    groups += GroupAssignment.find_all_by_assignment_id(assignment)
    return(groups.uniq)
  end

  def group_participants(group_assignment)
    return(GroupParticipant.all_by_group_assignment(group_assignment))
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
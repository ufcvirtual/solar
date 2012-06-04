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

end
module GroupAssignmentHelper
  
  def group_assignments(assignment)
    return(GroupAssignment.find_all_by_assignment_id(assignment))
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
  # Retorna todos os alunos daquela turma
  ##
  def all_students(assignment_id)
    assignment_allocation_tag_id = Assignment.find(assignment_id).allocation_tag_id
    return(Profile.students_of_class(assignment_allocation_tag_id))
  end

end
module GroupAssignmentHelper
  
  def group_assignments(assignment)
    return(GroupAssignment.find_all_by_assignment_id(assignment))
  end

  def group_participants(group_assignment)
    return(GroupParticipant.all_by_group_assignment(group_assignment))
  end

end
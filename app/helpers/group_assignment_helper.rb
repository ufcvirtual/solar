module GroupAssignmentHelper
  
  def group_assignments(assignment)
    return(GroupAssignment.find_all_by_assignment_id(assignment))
  end

  def group_participants(group_assignment)
    return(GroupParticipant.find_all_by_group_assignment_id(group_assignment))
  end

end
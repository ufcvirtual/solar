module GroupParticipantsHelper

  ##
  # Retorna informações dos participantes de um grupo
  ##
	def info_assignment_group_participant(user_id, can_manage_group, group)
		can_be_moved 	= (AssignmentFile.find_all_by_user_id_and_send_assignment_id(user_id, group.send_assignment.id).empty? and can_manage_group) unless group.send_assignment.nil?
		error_message = can_be_moved ? nil : t(:already_sent_files, :scope => [:portfolio, :group_assignments])
    error_message = can_manage_group ? error_message : t(:already_evaluated, :scope => [:portfolio, :group_assignments])
    error_message = t(:student_move_error, :scope => [:portfolio, :group_assignments]) + ", " + error_message.to_s unless error_message.nil?
    return {"can_be_moved" => can_be_moved, "error_message" => error_message}
	end

end
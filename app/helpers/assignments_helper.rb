module AssignmentsHelper

	  # recupera o icone correspondente ao tipo de arquivo
  def icon_attachment(file)
    case File.extname(file)
      when '.pdf'
        'mimetypes/pdf.png'
      when '.doc', '.docx', '.odt', '.fodt'
        'mimetypes/document.png'
      when '.xls', '.xlsx', '.ods', '.fods'
        'mimetypes/spreadsheet.png'
      when '.ppt', '.pptx', '.odp', '.fodp'
        'mimetypes/presentation.png'
      when '.odf', '.tex'
        'mimetypes/formula.png'
      when '.txt'
        'mimetypes/text.png'
      when '.rtf'
        'mimetypes/rtf.png'
      when '.link', '.html', '.htm'
        'mimetypes/url.png'
      when '.css'
        'mimetypes/css.png'
      when '.png', '.jpg', '.jpeg', '.bmp', '.xcf'
        'mimetypes/image.png'
      when '.mp3', '.wav', '.m4a', '.wav'
        'mimetypes/audio.png'
      when '.avi', '.mpg', '.mp4'
        'mimetypes/video.png'
      when '.zip', '.7z', '.rar', '.ace'
        'mimetypes/zip.png'
      when '.fla', '.swf'
        'mimetypes/flash.png'
      when '.svg', '.ai', '.odg', '.fodg'
        'mimetypes/vector.png'
      when '.sla', '.scd'
        'mimetypes/scribus.png'
      else
        'mimetypes/default.png'
    end
  end

  # Verifica se uma data esta em um intervalo de outras
  def verify_date_range(start_date, end_date, date)
    return date > start_date && date < end_date
  end

  ##
  # Verifica período que o responsável pode alterar algo na atividade
  ##
  def assignment_in_time?(assignment)
    # se responsável
    if assignment.allocation_tag.is_user_class_responsible?(current_user.id)
      can_access_assignment = (assignment.closed? and assignment.extra_time?(current_user.id)) #verifica se possui tempo extra
    end
    if verify_date_range(assignment.schedule.start_date, assignment.schedule.end_date, Time.now) or can_access_assignment
      return true
    else
      return false
    end
  end

  ##
  # Informações do andamento da atividade de um aluno
  ##
  def assignment_participant_info(student_id, assignment_id)
    situation               = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student_id)
    send_assignment         = SendAssignment.find_by_assignment_id_and_user_id(assignment_id, student_id)
    have_comments           = send_assignment.nil? ? false : (!send_assignment.comment.nil? or !send_assignment.assignment_comments.empty?)
    grade                   = (send_assignment.nil? or send_assignment.grade.nil?) ? '-' : send_assignment.grade
    send_assignment_files   = send_assignment.nil? ? [] : send_assignment.assignment_files
    file_delivery_date      = (send_assignment.nil? or send_assignment_files.empty?) ? '-' : send_assignment_files.first.attachment_updated_at.strftime("%d/%m/%Y") 
    return {"situation" => situation, "have_comments" => have_comments, "grade" => grade, "file_delivery_date" => file_delivery_date}
  end


  ##
  # Informações sobre o grupo que o aluno participa na atividade
  ##
  def student_assignment_group_info(assignment_id, student_id)
    groups_participants = GroupParticipant.find_group_participants(assignment_id, student_id)
    group_name          = groups_participants.first.group_assignment.group_name unless groups_participants.nil? unless groups_participants.nil?
    return {"group_name" => group_name, "groups_participants" => groups_participants}
  end

end

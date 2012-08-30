module PortfolioHelper

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
  def assignment_in_time?(assignment_id = nil)
    assignment = assignment.nil? ? Assignment.find(params['assignment_id']) : assignment_id
    if (verify_date_range(assignment.schedule.start_date, assignment.schedule.end_date, Time.now) or (assignment.closed? and assignment.extra_time?(current_user.id))) 
      return true
    else
      render :json => { :success => false, :flash_msg => t(:date_range_expired, :scope => [:portfolio, :notifications]), :flash_class => 'alert' } unless !assignment_id.nil?
      return false
    end
  end

  ##
  # Verifica se usuário é o responsável pelo assignment da atividade
  ##
  def must_be_responsible(assignment_id = nil)
    assignment = assignment.nil? ? Assignment.find(params['assignment_id']) : assignment_id
    if assignment.allocation_tag.is_user_class_responsible?(current_user.id)
      return true
    else
      render :json => { :success => false, :flash_msg => t(:no_permission), :flash_class => 'alert' } unless !assignment_id.nil?
      return false
    end
  end

  ##
  #
  ##
  def student_info_on_assignment(student, assignment)
    situation               = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment.id, student['id']) 
    student_send_assignment = SendAssignment.find_by_assignment_id_and_user_id(assignment.id, student['id'])
    have_comments           = student_send_assignment.nil? ? false : (!student_send_assignment.comment.nil? or !student_send_assignment.assignment_comments.empty?)
    grade                   = (student_send_assignment.nil? or student_send_assignment.grade.nil?) ? '-' : student_send_assignment.grade
    send_assignment_files   = student_send_assignment.nil? ? [] : student_send_assignment.assignment_files
    file_delivery_date      = (student_send_assignment.nil? or send_assignment_files.empty?) ? '-' : send_assignment_files.first.attachment_updated_at.strftime("%d/%m/%Y") 
    return {"situation" => situation, "have_comments" => have_comments, "grade" => grade, "file_delivery_date" => file_delivery_date}
  end


end

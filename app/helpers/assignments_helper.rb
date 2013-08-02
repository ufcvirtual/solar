module AssignmentsHelper

  ## recupera o icone correspondente ao tipo de arquivo
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

  ## Informações do andamento da atividade de um aluno
  def assignment_participant_info(student_id, assignment_id)
    assignment              = Assignment.find(assignment_id)
    situation               = assignment.situation_of_student(student_id)
    sent_assignment         = assignment.sent_assignment_by_user_id_or_group_assignment_id(student_id, nil)
    have_comments           = ((not sent_assignment.nil?) and (not sent_assignment.assignment_comments.empty?))
    grade                   = (sent_assignment.nil? or sent_assignment.grade.nil?) ? '-' : sent_assignment.grade
    sent_assignment_files   = sent_assignment.nil? ? [] : sent_assignment.assignment_files
    file_delivery_date      = (sent_assignment.nil? or sent_assignment_files.empty?) ? '-' : sent_assignment_files.first.attachment_updated_at.strftime("%d/%m/%Y") 
    return {"situation" => situation, "have_comments" => have_comments, "grade" => grade, "file_delivery_date" => file_delivery_date}
  end

end

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

  def edit_comment_buttons(assignment_id, own_comment, comment)
    edit_comment_button = '<div class="portfolio_comment_button">'
    # if assignment_in_time?(assignment_id) and own_comment
      edit_comment_button << '<%= button_tag "Excluir", :class => "btn btn_caution", :onclick => "remove_comment(#{comment.id}, #{assignment_id});" %>'
      edit_comment_button << '<%= button_tag "Editar", :class => "btn btn_default btn_edit_comment_#{comment.id}", :onclick => "btn_edit_comment(this, #{comment.id});" %>'
    # else
    #   edit_comment_button << '<a class="forum_post_link_disabled portfolio_link_disabled">Remover</a>&nbsp;&nbsp;'
    #   edit_comment_button << '<a class="portfolio_link_disabled">Editar</a>&nbsp;&nbsp;'
    # end
    edit_comment_button << '</div>'
  end

  ##
  # Verifica período que o responsável pode alterar algo na atividade
  ##
  def assignment_in_time?(assignment_id = nil)
    assignment = assignment.nil? ? Assignment.find(params['assignment_id']) : assignment_id
    if (verify_date_range(assignment.schedule.start_date, assignment.schedule.end_date, Time.now) or (assignment.closed? and assignment.extra_time?(current_user.id))) 
      return true
    else
      render :json => { :success => false, :flash_msg => t(:date_range_expired), :flash_class => 'alert' } unless !assignment_id.nil?
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
      render :json => { :success => false, :flash_msg => 'nao pode', :flash_class => 'alert' } unless !assignment_id.nil?
      return false
    end
  end

end

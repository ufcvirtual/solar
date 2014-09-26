include AccessControlHelper

class AccessControlController < ApplicationController

  ## Verificação de acesso ao realizar download de um arquivo relacionado à atividades ou um arquivo público
  def assignment
    attachment_name    = params[:file] 
    file_id            = attachment_name.slice(0..attachment_name.index("_")-1) 
    current_path_split = request.env['PATH_INFO'].split("/") #ex: /media/assignment/public_area/20_crimescene.png => ["", "media", "assignment", "public_area", "20_crimescene.png"]

    case current_path_split[current_path_split.size-2] #ex: ["", "media", "assignment", "public_area", "20_crimescene.png"] => public_area
      when 'comments' # arquivo de um comentário
        file = CommentFile.find(file_id)
        sent_assignment = file.assignment_comment.sent_assignment
        allocation_tags = sent_assignment.academic_allocation.allocation_tag_id
      when 'sent_assignment_files' # arquivo enviado pelo aluno/grupo
        file = AssignmentFile.find(file_id)
        sent_assignment = file.sent_assignment
        allocation_tags = sent_assignment.academic_allocation.allocation_tag_id
      when 'enunciation' # arquivo que faz parte da descrição da atividade
        file = AssignmentEnunciationFile.find(file_id)
        allocation_tags = active_tab[:url][:allocation_tag_id] || file.assignment.allocation_tags.pluck(:id)
        can_access = (can? :download, Assignment, on: [allocation_tags].flatten)
      when 'public_area' # área pública do aluno
        file = PublicFile.find(file_id) 
        same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)
        can_access = (can? :index, PublicFile, on: [file.allocation_tag_id])
    end

    is_observer_or_responsible = AllocationTag.find(active_tab[:url][:allocation_tag_id] || allocation_tags).is_observer_or_responsible?(current_user.id)
    can_access = (( sent_assignment.user_id.to_i == current_user.id or (not(sent_assignment.group.nil?) and sent_assignment.group.user_in_group?(current_user.id)) ) or is_observer_or_responsible) if (can_access.nil?)

    if can_access
      send_file(file.attachment.path, { disposition: 'inline', type: return_type(params[:extension])} )
    else
      raise CanCan::AccessDenied
    end
  end

  def lesson
    @lesson        = Lesson.find(params[:id])
    allocation_tag = active_tab[:url][:allocation_tag_id] || @lesson.allocation_tags.map(&:id).compact

    if current_user.is_admin?
      authorize! :show, Lesson
    else
      authorize! :show, Lesson, {on: [allocation_tag], read: true} # apenas para quem faz parte da turma
    end

    if @lesson.path(false).index('.html')
      if params[:index]
        file_path = Lesson::FILES_PATH.join(params[:id], [params[:file], '.', params[:extension]].join)
      else
        file_path = Lesson::FILES_PATH.join(params[:id], params[:folder], [params[:path], '.', params[:format]].join)
      end

      File.exist?(file_path) ? send_file(file_path, disposition: 'inline') : render(nothing: true)
    else
      send_file(@lesson.path(true), {disposition: 'inline', type: return_type(params[:extension])})
    end

  end

  def users
    user = User.find(params[:user_id])

    params[:style].gsub!(/\.\./, '')
    send_file user.photo.path(params[:style].intern), type: user.photo_content_type, disposition: 'inline'
  end

end

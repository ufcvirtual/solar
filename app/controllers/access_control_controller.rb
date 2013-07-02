include AccessControlHelper

class AccessControlController < ApplicationController

  ## Verificação de acesso ao realizar download de um arquivo relacionado à atividades ou um arquivo público
  def assignment
    attachment_name    = params[:file] 
    file_id            = attachment_name.slice(0..attachment_name.index("_")-1) 
    current_path_split = request.env['PATH_INFO'].split("/") #ex: /media/assignment/public_area/20_crimescene.png => ["", "media", "assignment", "public_area", "20_crimescene.png"]

    case current_path_split[current_path_split.size-2] #ex: ["", "media", "assignment", "public_area", "20_crimescene.png"] => public_area
      when 'comments' #arquivo de um comentário
        file = CommentFile.find(file_id)
        sent_assignment = file.assignment_comment.sent_assignment
        authorize! :download_files, sent_assignment.assignment
      when 'sent_assignment_files' #arquivo enviado pelo aluno/grupo
        file = AssignmentFile.find(file_id)
        sent_assignment = file.sent_assignment
        authorize! :download_files, sent_assignment.assignment
      when 'enunciation' #arquivo que faz parte da descrição da atividade
        file = AssignmentEnunciationFile.find(file_id)
        authorize! :download_files, file.assignment
      when 'public_area' #área pública do aluno
        file = PublicFile.find(file_id) 
        authorize! :download_files, Assignment
        same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)
    end

    # verifica se tem acesso a arquivo ou se é da mesma turma (definido apenas para arquivos públicos)
    if (not(sent_assignment.nil?) and sent_assignment.assignment.user_can_access_assignment(current_user.id, sent_assignment.user_id, sent_assignment.group_assignment_id)) or (same_class)
      send_file(file.attachment.path, { disposition: 'inline', type: return_type(params[:extension])} )
    else
      raise CanCan::AccessDenied
    end
  end

  def lesson
    @lesson = Lesson.find(params[:id])
    authorize! :show, Lesson, {on: [@lesson.allocation_tag.id], read: true}

    if @lesson.path(false).index('.html')
      if params[:index]
        file_path = Lesson::FILES_PATH.join(params[:id], [params[:file], '.', params[:extension]].join)
      else
        file_path = Lesson::FILES_PATH.join(params[:id], params[:folder], [params[:path], '.', params[:format]].join)
      end

      if File.exist? file_path
        render file: file_path, layout: false
      else
        render nothing: true
      end
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

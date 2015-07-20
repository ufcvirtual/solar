class AccessControlController < ApplicationController
  include AccessControlHelper

  ## Verificação de acesso ao realizar download de um arquivo relacionado à atividades ou um arquivo público
  def assignment
    file_id            = params[:file].split('_')[0]
    current_path_split = request.env['PATH_INFO'].split('/') #ex: /media/assignment/public_area/20_crimescene.png => ["", "media", "assignment", "public_area", "20_crimescene.png"]

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
      send_file(file.attachment.path, { disposition: 'inline', type: return_type(params[:extension])})
    else
      raise CanCan::AccessDenied
    end
  end

  def bibliography
    get_file(Bibliography, 'bibliography')
  end

  def support_material
    get_file(SupportMaterialFile, 'support_material_files')
  end

  # def post
  # end

  def message
    file = MessageFile.find(params[:file].split('_')[0])
    raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)
    download_file('messages')
  end

  def lesson
    lessons = [lesson  = Lesson.find(params[:id])]
    lessons << lesson.imported_to

    verify(lessons.flatten.map(&:allocation_tags).flatten.map(&:id).flatten.compact, Lesson, :show, true, true)

    if lesson.path(false).index('.html')
      if params[:index]
        file_path = File.join(Lesson::FILES_PATH, params[:id], [params[:file], '.', params[:extension]].join)
      else
        file_path = File.join(Lesson::FILES_PATH, params[:id], params[:folder], [params[:path], '.', params[:format]].join)
      end
      send_file(file_path, { disposition: 'inline' })
    else
      send_file(lesson.path(true), { disposition: 'inline', type: return_type(params[:extension]) })
    end
  end

  def users
    user = User.find(params[:user_id])
    send_file user.photo.path(params[:style]), type: user.photo_content_type, disposition: 'inline'
  end

  private

    def verify(ats, model, method=:show, accepts_general_profile=true, any=true)
      allocation_tags = active_tab[:url][:allocation_tag_id] || ats
      authorize! method, model, { on: allocation_tags, read: true, accepts_general_profile: accepts_general_profile, any: any }
    end

    def get_file(model, path, method=:download)
      object = model.find(params[:file].split('_')[0])
      verify(object.allocation_tags.map(&:id).flatten.compact, model, :download)
      download_file(path)
    end

    def download_file(path)
      file_path = File.join("#{Rails.root}", 'media', path, "#{params[:file]}.#{params[:extension]}")  
      File.exist?(file_path) ? send_file(file_path, disposition: 'inline') : render(nothing: true)
    end

end

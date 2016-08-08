class AccessControlController < ApplicationController
  include AccessControlHelper

  before_filter :set_current_user

  ## Verificação de acesso ao realizar download de um arquivo relacionado à atividades ou um arquivo público
  def assignment
    unless user_session[:blocking_content]
      file_id            = params[:file].split('_')[0]
      current_path_split = request.env['PATH_INFO'].split('/') #ex: /media/assignment/public_area/20_crimescene.png => ["", "media", "assignment", "public_area", "20_crimescene.png"]

      case current_path_split[current_path_split.size-2] #ex: ["", "media", "assignment", "public_area", "20_crimescene.png"] => public_area
        when 'comments' # arquivo de um comentário
          file = CommentFile.find(file_id)
          acu = file.assignment_comment.academic_allocation_user
          allocation_tags = acu.academic_allocation.allocation_tag_id
        when 'sent_assignment_files' # arquivo enviado pelo aluno/grupo
          file = AssignmentFile.find(file_id)
          acu  = file.academic_allocation_user
          allocation_tags = acu.academic_allocation.allocation_tag_id
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
      can_access = (( acu.user_id.to_i == current_user.id || (!(acu.group.nil?) && acu.group.user_in_group?(current_user.id)) ) or is_observer_or_responsible) if (can_access.nil?)

      if can_access
        send_file(file.attachment.path, { disposition: 'inline', type: return_type(params[:extension])})
      else
        raise CanCan::AccessDenied
      end
    else  
      raise CanCan::AccessDenied
    end
  end

  def bibliography
    get_file(Bibliography, 'bibliography')
  end

  def support_material
    unless user_session[:blocking_content]
      get_file(SupportMaterialFile, 'support_material_files')
    end  
  end

  def question_image 
    question = QuestionImage.find(params[:file].split('_')[0]).question
    question.can_see?
    download_file(File.join('questions', 'images'))
  end

  def question_item
    question = QuestionItem.find(params[:file].split('_')[0]).question
    question.can_see?
    download_file(File.join('questions', 'items'))
  end

  #def post
  #end

  def message
    unless user_session[:blocking_content]
      file = MessageFile.find(params[:file].split('_')[0])
      raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)
      download_file('messages')
    end
  end

  def exam
    if session[:blocking_content]==false
      exams = [exam  = Exam.find(params[:id])]
      verify(exams.flatten.map(&:allocation_tags).flatten.map(&:id).flatten.compact, Exam, :show, true, true)
      if exam.path(false).index('.html')
        if params[:index]
          file_path = File.join(Exam::FILES_PATH, params[:id], [params[:file], '.', params[:extension]].join)
        else
          file_path = File.join(Exam::FILES_PATH, params[:id], params[:folder], [params[:path], '.', params[:format]].join)
        end
        send_file(file_path, { disposition: 'inline' })
      else
        send_file(exam.path(true), { disposition: 'inline', type: return_type(params[:extension]) })
      end
    end
  end

  def lesson
    unless user_session[:blocking_content]
      lessons = [lesson  = Lesson.find(params[:id])]

      if user_session[:lessons].include?(params[:id])
        lessons << lesson.imported_to
        verify(lessons.flatten.map(&:allocation_tags).flatten.map(&:id).flatten.compact, Lesson, :show, true, true)
        user_session[:lessons] += lessons.flatten.map(&:id).flatten
      end

      if lesson.path(false).index('.html')
        if params[:index]
          file_path = File.join(Lesson::FILES_PATH, params[:id], [params[:file], '.', params[:extension]].join)
        else
          file_path = File.join(Lesson::FILES_PATH, params[:id], params[:folder], [params[:path], '.', params[:format]].join)
        end
        send_file(file_path, { disposition: 'inline' })
      else
        path = lesson.path(true)
        params[:extension] = path.split('.').last if params[:extension].nil?
        send_file(path, { disposition: 'inline', type: return_type(params[:extension]) })
      end
    end
  end

  def users
    user = User.find(params[:user_id])
    file_path = user.photo.path(params[:style])
    if File.exist?(file_path)
      send_file file_path, type: user.photo_content_type, disposition: 'inline'
    else
      render :nothing => true, :status => 200, :content_type => 'text/html'
    end
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

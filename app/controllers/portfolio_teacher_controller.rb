class PortfolioTeacherController < ApplicationController

  include FilesHelper
  include PortfolioHelper
  include AccessControlHelper

  before_filter :prepare_for_group_selection, :only => [:index]
  before_filter :user_related_to_assignment?, :except => [:index]
  before_filter :assignment_in_time?, :must_be_responsible, :except => [:index, :individual_activity, :assignment, :download_files]
  before_filter :assignment_file_download, :only => [:download_files]
  authorize_resource

  def index
    allocation_tag_id      = active_tab[:url]['allocation_tag_id']
    @individual_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Individual_Activity)
    @group_activities      = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Group_Activity)
  end


  ##
  # Informações da atividade individual escolhida na listagem com a lista de alunos daquela turma
  ##
  def individual_activity
    @activity           = Assignment.find(params[:assignment_id])
    allocation_tags     = AllocationTag.find_related_ids(@activity.allocation_tag_id).join(',')
    @students           = PortfolioTeacher.list_students_by_allocations(allocation_tags) #alunos participantes da atividade
    @assignment_files   = AssignmentEnunciationFile.find_all_by_assignment_id(@activity.id)  #arquivos que fazem parte da descrição da atividade
    @grade              = []
    @comments           = []
    @situation          = []
    @file_delivery_date = []

    @students.each_with_index do |student, idx| #informações de cada aluno
      @situation[idx]          = Assignment.status_of_actitivy_by_assignment_id_and_student_id(@activity.id, student['id']) 
      student_send_assignment  = SendAssignment.find_by_assignment_id_and_user_id(@activity.id, student['id'])
      @comments[idx]           = student_send_assignment.nil? ? false : (!student_send_assignment.comment.nil? or !student_send_assignment.assignment_comments.empty?)
      @grade[idx]              = (student_send_assignment.nil? or student_send_assignment.grade.nil?) ? '-' : student_send_assignment.grade
      send_assignment_files    = student_send_assignment.nil? ? [] : student_send_assignment.assignment_files
      @file_delivery_date[idx] = (student_send_assignment.nil? or send_assignment_files.empty?) ? '-' : send_assignment_files.first.attachment_updated_at.strftime("%d/%m/%Y") 
    end
  end

  ##
  # Informações do andamento da atividade para um aluno/grupo escolhido
  # Nesta página, há as opções de comentários para o trabalho do aluno/grupo, avaliação e afins
  ##
  def assignment
    @assignment      = Assignment.find(params[:assignment_id]) 
    @student_id      = params[:student_id].nil? ? nil : params[:student_id] 
    @group_id        = params[:group_id].nil? ? nil : params[:group_id] 
    @group           = GroupAssignment.find(params[:group_id]) unless @group_id.nil? #grupo
    @user            = current_user
    @comments_files  = []
    @users_profiles  = []
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
   
    unless @send_assignment.nil? #informações do andamento da atividade do aluno
      @files_sent_assignment = @send_assignment.assignment_files
      @comments              = @send_assignment.assignment_comments.order("updated_at DESC")

      @comments.each_with_index do |comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        @users_profiles[idx] = Profile.find(profile_id)
        @comments_files[idx] = comment.comment_files
      end
    end

    # perfil do usuário para exibir em possíveis novos comentários
    profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
    @user_profile = Profile.find(profile_id)
  end

  ##
  # Avalia trabalho do aluno / grupo
  ##
  def evaluate
    @assignment = Assignment.find(params['assignment_id'])
    student_id  = (params[:student_id].nil? or params[:student_id].blank?) ? nil : params[:student_id]
    group_id    = (params[:group_id].nil? or params[:group_id].blank?) ? nil : params[:group_id]
    grade       = params['grade'].blank? ? params['grade'] : params['grade'].tr(',', '.').to_f 
    comment     = params['comment']

    begin
      @send_assignment = SendAssignment.find_or_create_by_assignment_id_and_group_assignment_id_and_user_id(@assignment.id, group_id, student_id)
      @send_assignment.update_attributes!(:grade => grade, :comment => comment)

      respond_to do |format|
        format.html { render 'evaluate_assignment_student_div', :layout => false }
      end
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message.split(',')[0], :flash_class => 'alert' }
    end

  end

  ##
  # Envia comentarios do professor (cria e edita)
  ##
  def send_comment
    @assignment       = Assignment.find(params[:assignment_id])
    comment           = params[:comment_id].nil? ? nil : AssignmentComment.find(params[:comment_id]) #verifica se comentário já existe. se sim, é edição; se não, é criação.
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    comment_files     = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",") #["id_arquivo_del1,id_arquivo_del2"] => ["id_arquivo_del1", "id_arquivo_del2"]

    if (comment.nil? or comment.user_id == current_user.id) #se for criar comentário ou se estiver editando o próprio comentário
      send_assignment = SendAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id)

      begin
        ActiveRecord::Base.transaction do

          if comment.nil?
            comment = AssignmentComment.create!(:user_id => current_user.id, :comment => comment_text, :send_assignment_id => send_assignment.id, :updated_at => Time.now)
          else
            comment.update_attributes!(:comment => comment_text, :updated_at => Time.now)
          end
          
          comment_files.each do |file|
            CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id })
          end

          deleted_files_ids.each do |deleted_file_id|
            CommentFile.find(deleted_file_id).delete_comment_file unless deleted_file_id.blank?
          end
        end

      rescue Exception => error
        flash[:alert] = error.message
      end
    else
      flash[:alert] = t(:no_permission)
    end
    redirect_to request.referer
  end

  ##
  # Remover comentário
  ##
  def remove_comment
    comment = AssignmentComment.find(params[:comment_id])

    if comment.user_id == current_user.id #se for dono do comentário
      begin
        ActiveRecord::Base.transaction do

          comment.comment_files.each do |file|
            file.delete_comment_file
          end
          comment.delete

        end
        render :json => { :success => true, :flash_msg => t(:portfolio_removed_comment), :flash_class => 'notice' }
      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
      end
    else
      render :json => { :success => false, :flash_msg => t(:no_permission), :flash_class => 'alert' }
    end

  end

  ##
  # Download dos arquivos do portfolio (seja enviado pelo aluno/grupo, enviado no comentário do professor ou que faça parte da descrição da atividade)
  ##
  def download_files
    if params.include?('zip') #se for baixar todos como zip
      folder_name = ''
      assignment = Assignment.find(params[:assignment_id])

      case params[:type]
        when 'assignment' #arquivos enviados pelo aluno/grupo
          send_assignment = assignment.send_assignments.where(:user_id => params[:student_id], :group_assignment_id => params[:group_id]).first
          folder_name = [assignment.name, (params[:group_id].nil? ? send_assignment.user.nick : send_assignment.group_assignment.group_name)].join(' - ')#pasta: "atv1 - aluno1"
          all_files = send_assignment.assignment_files
        when 'enunciation' #arquivos que fazem parte da descrição da atividade
          folder_name = assignment.name #pasta: "atv1"
          all_files = assignment.assignment_enunciation_files
      end

      file_path = make_zip_files(all_files, 'attachment_file_name', folder_name) #caminho do zip criado
    else

      file = case params[:type]
        when 'comment' #arquivo de um comentário
          CommentFile.find(params[:file_id])
        when 'assignment' #arquivo enviado pelo aluno/grupo
          AssignmentFile.find(params[:file_id])
        when 'enunciation' #arquivo que faz parte da descrição da atividade
          AssignmentEnunciationFile.find(params[:file_id])
      end

      file_path = file.attachment.path #caminho do arquivo
    end

    download_file(request.referer, file_path)
  end

end

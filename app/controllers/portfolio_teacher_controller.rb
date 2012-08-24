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
    @activity           = Assignment.find(params[:assignment_id]) #atividiade individual
    allocation_tags     = AllocationTag.find_related_ids(@activity.allocation_tag_id).join(',')
    @students           = PortfolioTeacher.list_students_by_allocations(allocation_tags) #alunos participantes da atividade (da turma)
    @assignment_files   = AssignmentEnunciationFile.find_all_by_assignment_id(@activity.id) 
    @grade              = []
    @comments           = []
    @situation          = []
    @file_delivery_date = []

    @students.each_with_index do |student, idx|
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
    @group           = GroupAssignment.find(params[:group_id]) unless @group_id.nil?
    @user            = current_user
    @comments_files  = []
    @users_profiles  = []
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
   
    unless @send_assignment.nil?
      @files_sent_assignment = @send_assignment.assignment_files
      @comments              = @send_assignment.assignment_comments.order("updated_at DESC")

      @comments.each_with_index do |comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        @users_profiles[idx] = Profile.find(profile_id)
        @comments_files[idx] = comment.comment_files
      end
    end

    profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
    @user_profile = Profile.find(profile_id)
  end

  ##
  # Avalia trabalho do aluno
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
    comment           = params[:comment_id].nil? ? nil : AssignmentComment.find(params[:comment_id]) 
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    comment_files     = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",")

    if (comment.nil? or comment.user_id == current_user.id)
      send_assignment = SendAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id)

      begin
        ActiveRecord::Base.transaction do
          if comment.nil?
            comment = AssignmentComment.create!(:user_id => current_user.id, :comment => comment_text, :send_assignment_id => send_assignment.id)
          else
            comment.update_attribute(:comment, comment_text)
          end
          comment.update_attribute(:updated_at, Time.now)
          
          comment_files.each do |file|
            CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id})
          end

          deleted_files_ids.each do |deleted_file_id|
            delete_file(deleted_file_id) unless deleted_file_id.blank?
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
    if comment.user_id == current_user.id
      begin
        ActiveRecord::Base.transaction do
          files_comment = CommentFile.find_all_by_assignment_comment_id(comment.id)
          files_comment.each do |file|
            delete_file(file.id)
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
  # Download dos arquivos do comentario do professor ou enviados pelo aluno
  ##
  def download_files
    if params.include?('zip')
      folder_name = ''
      assignment = Assignment.find(params[:assignment_id])

      case params[:type]
        when 'assignment'
          sa = assignment.send_assignments.where(:user_id => params[:student_id], :group_assignment_id => params[:group_id]).first

          # "atv1 - aluno1"
          folder_name = [assignment.name, (params[:group_id].nil? ? sa.user.nick : sa.group_assignment.group_name)].join(' - ')
          all_files = sa.assignment_files
        when 'enunciation'
          folder_name = assignment.name
          all_files = assignment.assignment_enunciation_files
      end

      file_path = make_zip_files(all_files, 'attachment_file_name', folder_name)
    else
      file = case params[:type]
        when 'comment'
          CommentFile.find(params[:file_id])
        when 'assignment'
          AssignmentFile.find(params[:file_id])
        when 'enunciation'
          AssignmentEnunciationFile.find(params[:file_id])
      end

      file_path = file.attachment.path
    end

    download_file(request.referer, file_path)
  end

  private

    ##
    # Deleta arquivos enviados
    ##
    def delete_file(file_id)
      begin
        # recupera o nome do arquivo a ser feito o download
        filename = CommentFile.find(file_id).attachment_file_name
        # arquivo a ser deletado
        file = "#{::Rails.root.to_s}/media/portfolio/comments/#{file_id}_#{filename}"
        # deletar arquivo da base de dados
        if CommentFile.find(file_id).delete
          # deletar arquivos do servidor
          File.delete(file) if File.exist?(file)
        else
          raise t(:error_delete_file)
        end
      rescue Exception => error
        flash[:alert] = error.message
      end
    end

end
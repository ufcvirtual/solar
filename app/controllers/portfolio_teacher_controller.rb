class PortfolioTeacherController < ApplicationController

  include FilesHelper
  include PortfolioHelper
  include AccessControlHelper

  before_filter :prepare_for_group_selection, :only => [:index]
  before_filter :user_related_to_assignment?, :except => [:index]
  before_filter :assignment_in_time?, :must_be_responsible, :except => [:index, :individual_activity_detail, :student_or_group_assignment]
  # load_and_authorize_resource

  def index
    allocation_tag_id      = active_tab[:url]['allocation_tag_id']
    @individual_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Individual_Activity)
    @group_activities      = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Group_Activity)
  end

  def individual_activity_detail
    @activity     = Assignment.find(params[:assignment_id])

    # alunos da atividade
    allocation_tags     = AllocationTag.find_related_ids(@activity.allocation_tag_id).join(',')
    @students           = PortfolioTeacher.list_students_by_allocations(allocation_tags)
    # arquivos anexados à atividade
    @assignment_files   = AssignmentEnunciationFile.find_all_by_assignment_id(@activity.id)
    # informações do andamento do trabalho de cada aluno
    @grade              = []
    @comments           = []
    @situation          = []
    @file_delivery_date = []

    @students.each_with_index do |student, idx|
      @situation[idx] = Assignment.status_of_actitivy_by_assignment_id_and_student_id(@activity.id, student['id'])
      student_send_assignment = SendAssignment.find_by_assignment_id_and_user_id(@activity.id, student['id'])
      @comments[idx] = student_send_assignment.nil? ? false : (!student_send_assignment.comment.nil? or !AssignmentComment.find_all_by_send_assignment_id(student_send_assignment.id).empty?)
      @grade[idx] = (student_send_assignment.nil? or student_send_assignment.grade.nil?) ? '-' : student_send_assignment.grade
      send_assignment_files = student_send_assignment.nil? ? [] : AssignmentFile.find_all_by_send_assignment_id(student_send_assignment.id) 
      @file_delivery_date[idx] = (student_send_assignment.nil? or send_assignment_files.empty?) ? '-' : send_assignment_files.first.attachment_updated_at.strftime("%d/%m/%Y") 
    end

  end

  def student_or_group_assignment
    @assignment            = Assignment.find(params[:assignment_id])
    @student_id            = params[:student_id].nil? ? nil : params[:student_id]
    @group_id              = params[:group_id].nil? ? nil : params[:group_id]
    @group                 = GroupAssignment.find(params[:group_id]) unless @group_id.nil?
    @user                  = current_user
    @comments              = []
    @comments_files        = []
    @users_profiles        = []
    @files_sent_assignment = []
    
    @send_assignment       = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
    @files_sent_assignment = AssignmentFile.find_all_by_send_assignment_id(@send_assignment.id) unless @send_assignment.nil?
    
    unless @send_assignment.nil?
      assignment_comments = AssignmentComment.find_all_by_send_assignment_id(@send_assignment.id, :order => "updated_at DESC")
      @comments           = assignment_comments.nil? ? [] : assignment_comments
      

      @comments.each_with_index do |comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        
        # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
        @users_profiles[idx] = Profile.find(profile_id)

        @comments_files[idx] = CommentFile.find_all_by_assignment_comment_id(comment.id)
      end
    end

    profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
    # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
    @user_profile = Profile.find(profile_id)

  end

  ##
  # Avalia trabalho do aluno
  ##
  def evaluate_student_assignment
    @assignment = Assignment.find(params['assignment_id'])
    student_id  = (params[:student_id].nil? or params[:student_id].blank?) ? nil : params[:student_id]
    group_id    = (params[:group_id].nil? or params[:group_id].blank?) ? nil : params[:group_id]
    grade       = (params['grade'].nil? or params['grade'].blank?) ? nil : params['grade'].tr(',', '.').to_f
    comment     = (params['comment'].nil? or params['comment'].blank?) ? nil : params['comment']

      begin
        if grade < 0 || grade > 10
          raise t(:invalid_grade)
        end unless grade.nil?

        @send_assignment = SendAssignment.find_or_create_by_assignment_id_and_group_assignment_id_and_user_id(@assignment.id, group_id, student_id)

        @send_assignment.update_attribute(:grade, grade)
        @send_assignment.update_attribute(:comment, comment)

        respond_to do |format|
          format.html { render 'evaluate_assignment_student_div', :layout => false }
        end
      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
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
            comment.update_attribute(:updated_at, Time.now)
          else
            comment.update_attribute(:comment, comment_text)
            comment.update_attribute(:updated_at, Time.now)
          end
          
          comment_files.each do |file|
            comment = CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id})
          end

          unless comment.nil?
            deleted_files_ids.each do |deleted_file_id|
              delete_file(deleted_file_id) unless deleted_file_id.blank?
            end
          end
        end

        redirect_to :action => :student_or_group_assignment, :student_id => student_id, :group_id => group_id, :assignment_id => @assignment.id, :error_message => nil

      rescue Exception => error
        # redirect_to :action => :student_or_group_assignment, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => error.message
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
        # render :student_or_group_assignment
      end
    else
      # redirect_to :action => :student_or_group_assignment, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => t(:date_range_expired)
      render :json => { :success => false, :flash_msg => "sem permissao", :flash_class => 'alert', :cancel => true}
    end

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
        render :json => { :success => true, :flash_msg => "comentario removido", :flash_class => 'notice' }
      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
      end
    else
      render :json => { :success => false, :flash_msg => "sem permissao", :flash_class => 'alert' }
    end
  end

  ## Downloads

  ##
  # Download dos arquivos do comentario do professor ou enviados pelo aluno
  ##
  def download_individual_file
    ########################
    #precisa ter permissão, ser o responsável ou o próprio aluno/participante do grupo
    #mas essa página só é acessada pelos responsáveis, entãoe sse método específico não considera aluno/participante do grupo, mas filtro de arquivo sim
    ########################
    redirect_error = {:action => :student_or_group_assignment, :assignment_id => params[:assignment_id], :student_id => params[:student_id], :group_id => params[:group_id]}
    if params[:type] == "comment"
      file_path = CommentFile.find(params[:id]).attachment.path
    elsif params[:type] == "assignment"
      file_path = AssignmentFile.find(params[:id]).attachment.path
    elsif params[:type] == "enunciation"
      file_path = AssignmentEnunciationFile.find(params[:id]).attachment.path
      redirect_error = {:action => :individual_activity_detail, :assignment_id => params[:assignment_id]}
    end
    download_file(redirect_error, file_path)
  end

  ##
  # Download dos arquivos enviados pelo aluno zipados
  ##
  def download_all_student_or_group_files_zip
    ########################
    #precisa ter permissão, ser o responsável ou o próprio aluno/participante do grupo
    #mas essa página só é acessada pelos responsáveis, entãoe sse método específico não considera aluno/participante do grupo, mas filtro de arquivo sim
    ########################
    assignment     = Assignment.find(params[:assignment_id])
    name           = params[:group_id].nil? ? User.find(params[:student_id]).nick : GroupAssignment.find(params[:group_id]).group_name
    all_files      = params[:all_files].collect{ |file_id| AssignmentFile.find(file_id)}
    path_zip       = make_zip_files(all_files, 'attachment_file_name', assignment.name+" - "+name)
    redirect_error = {:action => :student_or_group_assignment, :assignment_id => params[:assignment_id], :student_id => params[:student_id], :group_id => params[:group_id]}
    download_file(redirect_error, path_zip)
  end

  ##
  # Download dos arquivos enviados pelo aluno zipados
  ##
  def download_all_enunciation_files_zip
    ########################
    #precisa ter permissão, ser o responsável ou o próprio aluno
    #mas essa página só é acessada pelos responsáveis, entãoe sse método específico não considera aluno, mas filtro de arquivo sim
    ########################
    assignment     = Assignment.find(params[:assignment_id])
    all_files      = params[:all_files].collect{ |file_id| AssignmentEnunciationFile.find(file_id)}
    path_zip       = make_zip_files(all_files, 'attachment_file_name', assignment.name)
    redirect_error = {:action => :individual_activity_detail, :assignment_id => params[:assignment_id]}
    download_file(redirect_error, path_zip)
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
      file_del = "#{::Rails.root.to_s}/media/portfolio/comments/#{file_id}_#{filename}"
      # deletar arquivo da base de dados
      if CommentFile.find(file_id).delete
        # deletar arquivos do servidor
        File.delete(file_del) if File.exist?(file_del)
      else
        raise t(:error_delete_file)
      end
    rescue Exception => error
      flash[:alert] = error.message
    end
  end

  ##
  # Download de arquivos
  ##
  def download_files_student
    authorize! :download_files_student, PortfolioTeacher

    redirect_error = {:action => :student_or_group_assignment, :id => params[:students_id], :send_assignment_id => params[:send_assignment_id]}
    download_file(redirect_error, AssignmentFile.find(params[:id]).attachment.path)
  end

end
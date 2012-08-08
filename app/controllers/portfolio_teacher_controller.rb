class PortfolioTeacherController < ApplicationController

  include FilesHelper
  include PortfolioHelper
  include AccessControlHelper

  before_filter :prepare_for_group_selection, :only => [:list]
  # before_filter :assignment_in_time?, :only => [:evaluate_student_assignment, :update_comment, :upload_files_comment_page, :upload_files_comment]

  def list
    authorize! :list, PortfolioTeacher
    allocation_tag_id      = active_tab[:url]['allocation_tag_id']
    # listando atividades individuais pela turma
    @individual_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Individual_Activity)
    @group_activities      = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Group_Activity)
  end

  def individual_activity_details
    assignment_id = params[:id]
    @activity     = Assignment.find(assignment_id)

    # verifica se os arquivos podem ser deletados
    # @delete_files = verify_date_range(@activity.schedule.start_date.to_time, @activity.schedule.end_date.to_time, Time.now)

    # alunos da atividade
    allocation_tags     = AllocationTag.find_related_ids(@activity.allocation_tag_id).join(',')
    @students           = PortfolioTeacher.list_students_by_allocations(allocation_tags)
    # arquivos anexados à atividade
    @assignment_files   = AssignmentEnunciationFile.find_all_by_assignment_id(assignment_id)
    # informações do andamento do trabalho de cada aluno
    @grade              = []
    @comments           = []
    @situation          = []
    @file_delivery_date = []

    @students.each_with_index{|student, idx|
      @situation[idx] = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student['id'])
      student_send_assignment = SendAssignment.find_by_assignment_id_and_user_id(assignment_id, student['id'])
      @comments[idx] = student_send_assignment.nil? ? false : (!student_send_assignment.comment.nil? or !AssignmentComment.find_all_by_send_assignment_id(student_send_assignment.id).empty?)
      @grade[idx] = student_send_assignment.nil? ? '-' : student_send_assignment.grade
      assignments_send_assignment = student_send_assignment.nil? ? [] : AssignmentFile.find_all_by_send_assignment_id(student_send_assignment.id) 
      @file_delivery_date[idx] = (student_send_assignment.nil? or assignments_send_assignment.empty?) ? '-' : assignments_send_assignment.first.attachment_updated_at.strftime("%d/%m/%Y") 

    }

  end

  def student_detail
    authorize! :student_detail, PortfolioTeacher

    @assignment   = Assignment.find(params[:assignment_id])
    @user         = current_user
    @student_id   = params[:student_id].nil? ? nil : params[:student_id]
    @group_id     = params[:group_id].nil? ? nil : params[:group_id]
    @group        = GroupAssignment.find(params[:group_id]) unless @group_id.nil?

    @files_sent_assignment = AssignmentFile.joins(:send_assignment).where("send_assignments.assignment_id = ? AND send_assignments.user_id = ? 
                                              AND send_assignments.group_assignment_id = ?", @assignment.id, @student_id, @group_id).order("
                                              assignment_files.attachment_updated_at DESC")
    @send_assignment       = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
    
    unless @send_assignment.nil?
      @comments       = AssignmentComment.find_all_by_send_assignment_id(@send_assignment.id, :order => "updated_at DESC") 
      @comments_files = []
      @users_profiles = []

      @comments.each_with_index{|comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        
        # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
        @users_profiles[idx] = Profile.find(profile_id)

        @comments_files[idx] = CommentFile.find_all_by_assignment_comment_id(comment.id)
      }

      profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
      # raise "#{Profile.find(profile_id)}"

      # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
      @user_profile = Profile.find(profile_id)
    end

    # @error_message = params[:error_message]
    # unless @error_message.nil?
    #   flash['alert'] = @error_message
    #   comment
    # end

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

    if assignment_in_time?

      @send_assignment = SendAssignment.find_by_assignment_id_and_group_assignment_id_and_user_id(@assignment.id, group_id, student_id)

      begin

        if grade < 0 || grade > 10
          raise t(:invalid_grade)
        end unless grade.nil?

        if @send_assignment.nil?

          @send_assignment = SendAssignment.create(:assignment_id => @assignment.id, :group_assignment_id => group_id, :user_id => student_id, :comment => comment, :grade => grade)

        else
          @send_assignment.update_attribute(:grade, grade)
          @send_assignment.update_attribute(:comment, comment)
        end

        respond_to do |format|
          format.html { render 'evaluate_assignment_student_div', :layout => false }
        end

      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
      end

    else
      render :json => { :success => false, :flash_msg => t(:date_range_expired), :flash_class => 'alert', :cancel => true }
    end

  end

  ##
  # Cria comentarios do professor
  ##
  def create_comment
    # authorize! :update_comment, PortfolioTeacher
    @assignment = Assignment.find(params[:assignment_id])
    student_id  = params[:student_id].nil? ? nil : params[:student_id]
    group_id    = params[:group_id].nil? ? nil : params[:group_id]
    comment     = params['comment']
    files       = params['comment_files'].nil? ? [] : params['comment_files']

    if assignment_in_time?
      send_assignment = SendAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id)

      begin
        ActiveRecord::Base.transaction do
          assignment_comment = AssignmentComment.create!(:user_id => current_user.id, :comment => comment, :send_assignment_id => send_assignment.id)
          assignment_comment.update_attribute(:updated_at, Time.now)
          
          files.each do |file|
            comment = CommentFile.create!({ :attachment => file, :assignment_comment_id => assignment_comment.id})
          end
        end

        redirect_to :action => :student_detail, :student_id => student_id, :group_id => group_id, :assignment_id => @assignment.id, :error_message => nil

      rescue Exception => error
        # redirect_to :action => :student_detail, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => error.message
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
        # render :student_detail
      end
    else
      redirect_to :action => :student_detail, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => t(:date_range_expired)
      # render :json => { :success => false, :flash_msg => t(:date_range_expired), :flash_class => 'alert', :cancel => true}
    end

  end

  ##
  # Edita comentarios
  ##
  def update_comment
    # authorize! :update_comment, PortfolioTeacher
    @assignment       = Assignment.find(params[:assignment_id])
    comment           = AssignmentComment.find(params[:comment_id])
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    files             = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",")
    
    if assignment_in_time?

      begin
        ActiveRecord::Base.transaction do
          comment.update_attribute(:comment, comment_text)
          comment.update_attribute(:updated_at, Time.now)
          
          files.each do |file|
            CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id})
          end

          deleted_files_ids.each do |deleted_file_id|
            delete_file(deleted_file_id) unless deleted_file_id.blank?
          end

        end

        redirect_to :action => :student_detail, :student_id => student_id, :group_id => group_id, :assignment_id => @assignment.id, :error_message => nil

      rescue Exception => error
        # redirect_to :action => :student_detail, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => error.message
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
        # render :student_detail
      end
    else
      redirect_to :action => :student_detail, :assignment_id => @assignment.id, :student_id => student_id, :group_id => group_id, :error_message => t(:date_range_expired)
      # render :json => { :success => false, :flash_msg => t(:date_range_expired), :flash_class => 'alert', :cancel => true}
    end

  end

  def remove_comment
    comment = AssignmentComment.find(params[:comment_id])
    if assignment_in_time?
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
      render :json => { :success => false, :flash_msg => "nao pode", :flash_class => 'alert' }
    end
  end

  #####################
  # FILES
  #####################

  ##
  # Deleta arquivos enviados
  ##

  def delete_file(file_id)
    begin
      # recupera o nome do arquivo a ser feito o download
      filename = CommentFile.find(file_id).attachment_file_name
      # arquivo a ser deletado
      file_del = "#{::Rails.root.to_s}/media/portfolio/comments/#{file_id}_#{filename}"
      error = false
      # deletar arquivo da base de dados
      error = true unless CommentFile.find(file_id).delete
      # deletar arquivos do servidor
      unless error
        File.delete(file_del) if File.exist?(file_del)
      else
        raise t(:error_delete_file)
      end
    rescue Exception
      flash[:alert] = t(:error_delete_file)
    end
  end

  ##
  # Download de arquivos
  ##
  def download_files_student
    authorize! :download_files_student, PortfolioTeacher

    redirect_error = {:action => :student_detail, :id => params[:students_id], :send_assignment_id => params[:send_assignment_id]}
    download_file(redirect_error, AssignmentFile.find(params[:id]).attachment.path)
  end

  def assignment_in_time? 
    assignment = Assignment.find(params['assignment_id'])
    # verificar se foi passado id do comentário. se foi, ele já existe, dai verifica no if \/ se o usuário na sessão é o dono do comentário
    unless (!assignment.closed? or assignment.extra_time?(current_user.id)) # futuramente: e se o usuário é o dono do comentário
      return false
    else
      return true
    end
    
  end
end

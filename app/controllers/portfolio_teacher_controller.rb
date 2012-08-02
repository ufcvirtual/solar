class PortfolioTeacherController < ApplicationController

  include FilesHelper
  include PortfolioHelper
  include AccessControlHelper

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, PortfolioTeacher

    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    # listando atividades individuais pela turma
    @individual_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Individual_Activity)
    @group_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Group_Activity)
  end

  def individual_activity_details
    assignment_id = params[:id]
    @activity = Assignment.find(assignment_id)

    # verifica se os arquivos podem ser deletados
    # @delete_files = verify_date_range(@activity.schedule.start_date.to_time, @activity.schedule.end_date.to_time, Time.now)

    # alunos da atividade

    allocation_tags = AllocationTag.find_related_ids(@activity.allocation_tag_id).join(',')
    @students = PortfolioTeacher.list_students_by_allocations(allocation_tags)

    # arquivos anexados à atividade
    @assignment_files = AssignmentEnunciationFile.find_all_by_assignment_id(assignment_id)

    # informações do andamento do trabalho de cada aluno
    @grade = []
    @comments = []
    @situation = []
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

    @assignment         = Assignment.find(params[:assignment_id])
    @user               = User.find(current_user.id)

    if @assignment.type_assignment == Individual_Activity

      @student_or_group = User.find(params[:id])
      @files_sent_assignment = AssignmentFile.joins(:send_assignment).where("send_assignments.assignment_id = ? AND assignment_files.user_id = ?",
                                                                            @assignment.id, @student_or_group.id).order("assignment_files.attachment_updated_at 
                                                                            DESC")
      @send_assignment = SendAssignment.find_by_assignment_id_and_user_id(@assignment.id, @student_or_group.id)

    elsif @assignment.type_assignment == Group_Activity

      @student_or_group = GroupAssignment.find(params[:id]) 
      @files_sent_assignment = AssignmentFile.joins(:send_assignment).where("send_assignments.assignment_id = ? AND send_assignments.group_assignment_id = ?",
                                                                            @assignment.id, @student_or_group.id).order("assignment_files.attachment_updated_at 
                                                                            DESC")
      @send_assignment = SendAssignment.find_by_assignment_id_and_group_assignment_id(@assignment.id, @student_or_group.id)

    end
    
    unless @send_assignment.nil?
      @comments       = AssignmentComment.find_all_by_send_assignment_id(@send_assignment.id) 
      @comments_files = []
      @users_profiles  = []

      @comments.each_with_index{|comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
        @users_profiles[idx] = Profile.find(profile_id)

        @comments_files[idx] = CommentFile.find_all_by_assignment_comment_id(comment.id)
      }

      profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
        # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
      @user_profile = Profile.find(profile_id)
    end

  end

  ##
  # Avalia trabalho do aluno
  ##
  def evaluate_student_assignment
    @assignment         = Assignment.find(params['assignment_id'])
    student_or_group_id = params['student_or_group_id']
    grade               = (params['grade'].nil? or params['grade'].blank?) ? nil : params['grade'].tr(',', '.').to_f
    comment             = (params['comment'].nil? or params['comment'].blank?) ? nil : params['comment']

    if @assignment.type_assignment == Group_Activity
      @send_assignment    = SendAssignment.find_by_assignment_id_and_group_assignment_id(@assignment.id, student_or_group_id)
    elsif @assignment.type_assignment == Individual_Activity
      @send_assignment    = SendAssignment.find_by_assignment_id_and_user_id(@assignment.id, student_or_group_id)
    end

    begin

      if grade < 0 || grade > 10
        raise t(:invalid_grade)
      end unless grade.nil?

      if @send_assignment.nil?
        if @assignment.type_assignment == Group_Activity
          @send_assignment = SendAssignment.create(:assignment_id => @assignment.id, :group_assignment_id => student_or_group_id, :comment => comment, :grade => grade)
        elsif @assignment.type_assignment == Individual_Activity
          @send_assignment = SendAssignment.create(:assignment_id => @assignment.id, :user_id => student_or_group_id, :comment => comment, :grade => grade)
        end
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

  end

  ##
  # Atualiza comentarios do professor
  ##
  def update_comment

    # authorize! :update_comment, PortfolioTeacher
    @assignment           = Assignment.find(params[:assignment_id])
    @student_or_group_id  = params['student_or_group_id']
    @user                 = User.find(current_user.id)
    comment               = params['comment']
    if @assignment.type_assignment == Group_Activity
      send_assignment      = SendAssignment.find_by_assignment_id_and_group_assignment_id(@assignment.id, @student_or_group_id)
      send_assignment      = SendAssignment.create(:group_assignment_id => @student_or_group_id, :assignment_id => @assignment.id) if send_assignment.nil?
    elsif @assignment.type_assignment == Individual_Activity
      send_assignment      = SendAssignment.find_by_assignment_id_and_user_id(@assignment.id, @student_or_group_id)
      send_assignment      = SendAssignment.create(:user_id => @student_or_group_id, :assignment_id => @assignment.id) if send_assignment.nil?
    end
    

    begin

      ActiveRecord::Base.transaction do
        assignment_comment  = AssignmentComment.create!(:user_id => @user.id, :comment => comment, :send_assignment_id => send_assignment.id, :updated_at => Date.current)
        @comments           = AssignmentComment.find_all_by_send_assignment_id(send_assignment.id) 
        @comments_files     = []
        @users_profiles     = []
        @comments.each_with_index{|comment, idx|
          profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
          # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
          @users_profiles[idx] = Profile.find(profile_id)
          @comments_files[idx] = CommentFile.find_all_by_assignment_comment_id(comment.id)
        }
      end

      profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, @user.id).profile_id
      # user_profile_id = current_user.profiles_with_access_on('student_detail', 'portfolio_teacher', allocation_tag_id, only_id = true).first
      @user_profile = Profile.find(@user.id)

      respond_to do |format|
          format.html { render 'comment_assignment_student_div', :layout => false }
      end

    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
    end

  end

  ##
  # Upload de arquivos em um comentário
  ##

  def upload_files_comment_page
    @comment_id = params[:id]
    @assignment_id = params[:assignment_id]
    @student_or_group_id = params[:student_or_group_id]
    render :layout => false
  end

  def upload_files_comment

    begin
      assignment = Assignment.find(params[:assignment_id])
      comment = AssignmentComment.find(params[:comment_id])

      # if ((not discussion.closed? or discussion.extra_time?(current_user.id)) and (post.user_id == current_user.id))
        files = params['comment_files'].nil? ? [] : params['comment_files']
        files.each do |file|
          @file = CommentFile.create!(:assignment_comment_id => comment.id, :attachment_updated_at => Date.current, :attachment_file_name => file.original_filename, :attachment_content_type => file.content_type, :attachment_file_size => file.size)
        end
      # else
        # raise "not_permited"
      # end
    rescue Exception => error
      raise "#{error.message}"
    end

    flash[:notice] = t(:comment_files_uploaded_successfully)
    redirect_to :controller => :portfolio_teacher, :action => :student_detail, :id => params[:student_or_group_id], :assignment_id => params[:assignment_id]

  end

  #####################
  # FILES
  #####################

  ##
  # Deleta arquivos enviados
  ##
  def delete_file

    authorize! :delete_file, PortfolioTeacher

    redirect = {:action => :student_detail, :id => params[:students_id], :send_assignment_id => params[:send_assignment_id]}

    respond_to do |format|

      begin

        comment_file_id = params[:comment_file_id]

        # recupera o nome do arquivo a ser feito o download
        filename = CommentFile.find(comment_file_id).attachment_file_name

        # arquivo a ser deletado
        file_del = "#{::Rails.root.to_s}/media/portfolio/comments/#{comment_file_id}_#{filename}"

        error = false

        # deletar arquivo da base de dados
        error = true unless CommentFile.find(comment_file_id).delete

        # deletar arquivos do servidor
        unless error
          File.delete(file_del) if File.exist?(file_del)
          flash[:notice] = t(:file_deleted)
          format.html { redirect_to(redirect) }
        else
          raise t(:error_delete_file)
        end
      rescue Exception
        flash[:alert] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end
    end
  end

  ##
  # Upload de arquivos para o comentario
  ##
  def upload_files

    authorize! :upload_files, PortfolioTeacher

    send_assignment_id = params[:send_assignment_id] #if params.include? :send_assignment_id
    student_id = params[:students_id] #if params.include? :students_id
    assignment_id = params[:assignment_id]
    teachers_id = current_user.id # professor

    # se nao existir send_assignment_id devera ser criado um
    if send_assignment_id.nil?
      send_assignment = SendAssignment.new do |sa|
        sa.assignment_id = assignment_id
        sa.user_id = student_id
      end
      send_assignment.save

      # recupera o id do registro criado
      send_assignment_id = send_assignment.id

    end

    # redireciona para os detalhes da atividade individual
    redirect = {:action => :student_detail, :id => student_id, :send_assignment_id => send_assignment_id}

    respond_to do |format|
      begin
        raise t(:error_no_file_sent) unless params.include? :comments_files

        assignment_comment = AssignmentComment.where(["send_assignment_id = ? AND user_id = ?", send_assignment_id, teachers_id]).first

        # verifica se o professor ja comentou
        if assignment_comment.nil?
          # se nao tiver comentario, cria um registro na tabela para fazer associacoes

          assignment_comment = AssignmentComment.new do |ac|
            ac.send_assignment_id = send_assignment_id
            ac.user_id = teachers_id
          end
          assignment_comment.save!
        end
        comments_files = CommentFile.new params[:comments_files]
        comments_files.assignment_comment_id = assignment_comment.id
        comments_files.save!

        flash[:notice] = t(:file_uploaded)
        format.html { redirect_to(redirect) }
      rescue Exception => error
        flash[:alert] = error.message
        format.html { redirect_to(redirect) }
      end
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
end

class PortfolioTeacherController < ApplicationController

  include FilesHelper
  include PortfolioHelper

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

    # recupera a atividade selecionada
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
      @file_delivery_date[idx] = student_send_assignment.nil? ? '-' : AssignmentFile.find_all_by_send_assignment_id(student_send_assignment.id).first.attachment_updated_at.strftime("%d/%m/%Y") 
    }

  end

  def student_detail
    authorize! :student_detail, PortfolioTeacher

    @assignment = Assignment.find(params[:assignment_id])
    @student = User.find(params[:id])

    @files_student_assignment = AssignmentFile.joins(:send_assignment).where("send_assignments.assignment_id = ? AND assignment_files.user_id = ?",
                                                                            @assignment.id, @student.id).order("assignment_files.attachment_updated_at 
                                                                            DESC")
    
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id(@assignment.id, @student.id)

    unless @send_assignment.nil?
      @comments = AssignmentComment.find_all_by_send_assignment_id(@send_assignment.id, current_user.id) 
      @comments_files = []

      @comments.each_with_index{|comment, idx|
        @comments_files[idx] = CommentFile.find_all_by_assignment_comment_id(comment.id)
      }
    end
  end

  ##
  # Avalia trabalho do aluno
  ##
  def evaluate_student_assignment
    assignment_id   = params['assignment_id']
    student_id      = params['student_id']
    grade           = (params['grade'].nil? or params['grade'].blank?) ? nil : params['grade'].to_f
    comment         = (params['comment'].nil? or params['comment'].blank?) ? nil : params['comment']
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id(assignment_id, student_id)

    begin

      if grade < 0 || grade > 10
        raise t(:invalid_grade)
      end unless grade.nil?

      if @send_assignment.nil?
        @send_assignment = SendAssignment.create(:assignment_id => assignment_id, :user_id => students_id, :comment => comment, :grade => grade)
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

    authorize! :update_comment, PortfolioTeacher

    # id da atividade
    assignment_id = params[:assignment_id]

    # id da resposta do aluno
    send_assignment_id = params[:send_assignment_id]

    # usuarios envolvidos
    professors_id = current_user.id
    students_id = params[:students_id]

    # nota do aluno
    grade = (params[:comments][:grade].nil? || params[:comments][:grade] == '') ? nil : params[:comments][:grade].to_f

    # comentario enviado pelo professor
    comment = (params[:comments][:comment].nil? || params[:comments][:comment] == '') ? nil : params[:comments][:comment]

    respond_to do |format|

      begin

        # verifica se ja existe um send_assignment
        if send_assignment_id.nil?

          send_assignment = SendAssignment.new do |s|
            s.assignment_id = assignment_id
            s.user_id = students_id
          end

          send_assignment.save!
          send_assignment_id = send_assignment.id

        end

        redirect = {
          :controller => :portfolio_teacher,
          :action => :student_detail,
          :id => students_id,
          :assignment_id => assignment_id,
          :send_assignment_id => send_assignment_id
        }

        # update comment do professor
        comment_teacher = AssignmentComment.find_by_send_assignment_id_and_user_id(send_assignment_id, professors_id)

        # registro de comentario do professor inexistente
        if comment_teacher.nil? # && !send_assignment_id.nil?

          # se nao fez comentario o registro nao existe na tarefa
          comment_teacher = AssignmentComment.new do |ac|
            ac.send_assignment_id = send_assignment_id
            ac.user_id = professors_id
          end

        end

        # insere comentario se nao for vazio
        comment_teacher.comment = comment unless comment_teacher.nil? || comment_teacher == ''

        # modifica nota do aluno
        students_grade = SendAssignment.find(send_assignment_id)

        students_grade.grade = grade unless students_grade.nil?

        if grade < 0 || grade > 10
          raise t(:invalid_grade)
        end unless grade.nil?

        # executar as modificacoes em uma transacao
        ActiveRecord::Base.transaction do
          comment_teacher.save!
          students_grade.save!
        end

        flash[:notice] = t(:comment_updated_successfully)
        format.html { redirect_to(redirect) }

      rescue Exception => except
        flash[:alert] = except.message
        format.html { redirect_to(redirect) }
      end

    end

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

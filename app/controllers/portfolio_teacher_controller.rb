class PortfolioTeacherController < ApplicationController

  include FilesHelper

  ##
  # Lista de portfolio dos alunos de uma turma
  ##
  def list

    authorize! :list, PortfolioTeacher

    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(allocation_tag_id)

    # grupo selecionado
    @group = AllocationTag.where("id IN (#{allocations.join(',')}) AND group_id IS NOT NULL").first.group
    @students = PortfolioTeacher.list_students_by_allocations(allocations)

  end

  ##
  # Detalha o portfolio do aluno para a turma em questao
  ##
  def student_detail

    authorize! :student_detail, PortfolioTeacher

    @assignment_id = params[:assignment_id]
    @send_assignment_id = params[:send_assignment_id]
    @student_id = params[:id]

    # recuperar o nome da atividade
    begin
      @activity = Assignment.find(@assignment_id).name
    rescue
      @activity = nil
    end

    # estudante
    @student = User.select("name").where(["id = ?", @student_id]).first

    # consulta a atividade do aluno em questao
    assignments = SendAssignment.joins("LEFT JOIN assignment_files ON assignment_files.send_assignment_id = send_assignments.id").
      where("send_assignments.id = ?", @send_assignment_id).
      order("assignment_files.attachment_updated_at DESC").first

    # recuperando os arquivos enviados pelo aluno
    @files = []
    @files = assignments.assignment_files unless assignments.nil?

    @grade = nil
    @grade = assignments.grade unless assignments.nil?

    # comentarios e arquivos do professor
    professor_id = current_user.id
    assignment_comment = AssignmentComment.find_by_send_assignment_id_and_user_id(@send_assignment_id, professor_id)
    @comment = assignment_comment.comment unless assignment_comment.nil?

    # arquivos
    @comments_files = []
    @comments_files = CommentFile.find(:all, :conditions => ["assignment_comment_id = ?", assignment_comment.id], :order => "attachment_updated_at DESC") unless assignment_comment.nil?

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

        flash[:success] = t(:comment_updated_successfully)
        format.html { redirect_to(redirect) }

      rescue Exception => except
        flash[:error] = except.message
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

          flash[:success] = t(:file_deleted)
          format.html { redirect_to(redirect) }

        else
          raise t(:error_delete_file)
        end

      rescue Exception
        flash[:error] = t(:error_delete_file)
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

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include? :comments_files

        assignment_comment = AssignmentComment.where(["send_assignment_id = ? AND user_id = ?", send_assignment_id, teachers_id]).first

        # verifica se o professor ja comentou
        if assignment_comment.nil?
          # se nao tiver comentario, cria um registro na tabela para fazer associacoes

          assignment_comment = AssignmentComment.new do |ac|
            ac.send_assignment_id = send_assignment_id
            ac.user_id = teachers_id
          end

          # salvando registro de comentario
          assignment_comment.save!

        end

        comments_files = CommentFile.new params[:comments_files]
        comments_files.assignment_comment_id = assignment_comment.id
        comments_files.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        flash[:error] = error.message
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

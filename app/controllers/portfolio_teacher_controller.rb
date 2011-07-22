class PortfolioTeacherController < ApplicationController

  before_filter :require_user
  before_filter :curriculum_unit_name

  # lista de portfolio dos alunos de uma turma
  def list

    authorize! :list, PortfolioTeacher

    groups_id = 3 # devera ser carregado a partir da escolha da combo de GROUP

    # seta novo valor para o grupo/turma selecionada pelo professor
    session[:opened_tabs][session[:active_tab]]["groups_id"] = groups_id

    # lista de estudantes da turma

    @students = User.joins(:allocations => [{:allocation_tag => [:group, :assignments]}, :profile]).
      select("DISTINCT users.id, users.name").
      where("profiles.student = TRUE AND groups.id = ?", groups_id).
      order("users.name")

  end

  # lista dos trabalhos passados pelo professor e a situacao do aluno selecionado
  def list_assignments

    authorize! :list_assignments, PortfolioTeacher

    # recupera turma selecionada
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    students_id = params[:id]

    @student = User.find(students_id)
    @activities = list_assignments_by_group_and_student(groups_id, students_id)

  end

  # detalha o portfolio do aluno para a turma em questao
  def student_detail

    authorize! :student_detail, PortfolioTeacher

    @assignment_id = params[:assignment_id]
    @send_assignment_id = params[:send_assignment_id]
    @students_id = params[:id]

    # recuperar o nome da atividade
    begin
      @activity = Assignment.find(@assignment_id).name
    rescue
      @activity = ''
    end

    # estudante
    @student = User.select("name").where(["id = ?", @students_id]).first

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

  # atualiza comentarios do professor
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

        redirect = {:action => :student_detail, :id => students_id, :assignment_id => assignment_id, :send_assignment_id => send_assignment_id}

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

  # deleta arquivos enviados
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

        error = 0

        # verificando se o arquivo ainda existe
        if File.exist?(file_del)

          # deleta o arquivo do servidor
          if File.delete(file_del)

            # retira o registro da base de dados
            if CommentFile.find(comment_file_id).delete

              flash[:success] = t(:file_deleted)
              format.html { redirect_to(redirect) }

            end

          else
            error = 1 # arquivo nao deletado
          end

        else
          error = 2 # arquivo inexistente
        end

        raise t(:error_delete_file) unless error == 0

      rescue Exception => except

        flash[:error] = except
        format.html { redirect_to(redirect) }

      end

    end

  end

  # upload de arquivos para o comentario
  def upload_files

    authorize! :upload_files, PortfolioTeacher

    send_assignment_id = params[:send_assignment_id] if params.include? :send_assignment_id
    students_id = params[:students_id] if params.include? :students_id
    teachers_id = current_user.id # professor

    # redireciona para os detalhes da atividade individual
    redirect = {:action => :student_detail, :id => students_id, :send_assignment_id => send_assignment_id}

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

  # download de arquivos
  def download_files_student

    authorize! :download_files_student, PortfolioTeacher

    redirect_error = {:action => :student_detail, :id => params[:students_id], :send_assignment_id => params[:send_assignment_id]}

    begin

      assignment_file_id = params[:id]

      file_ = AssignmentFile.find(assignment_file_id)
      filename = file_.attachment_file_name

      path_file = "#{::Rails.root.to_s}/media/portfolio/individual_area/"

      # id da atividade
      id = SendAssignment.find(file_.send_assignment_id).assignment_id

      # recupera arquivo
      download_file(redirect_error, path_file, filename, assignment_file_id)

    rescue

      respond_to do |format|
        flash[:success] = t(:error_nonexistent_file)
        format.html { redirect_to(redirect_error) }
      end

    end

  end

  private

  # recupera o nome do curriculum_unit
  def curriculum_unit_name
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"] # recupera unidade curricular da sessao
    @curriculum_unit = CurriculumUnit.select("id, name").where(["id = ?", curriculum_unit_id]).first
  end

  # lista com as atividades do aluno dentro na turma
  def list_assignments_by_group_and_student(groups_id, students_id)
    assignments = ActiveRecord::Base.connection.select_all <<SQL
      SELECT DISTINCT
             t1.name AS assignments_name,
             t1.id AS assignment_id,
             t1.start_date,
             t1.end_date,
             t2.grade,
             t2.id AS send_assignment_id,
             CASE
                WHEN t2.grade IS NOT NULL THEN 'corrected'
                WHEN COUNT(t3.id) > 0 THEN 'sent'
                WHEN COUNT(t3.id) = 0 AND t1.end_date > now() THEN 'not_sent'
                ELSE '-'
             END AS situation
        FROM assignments      AS t1
        JOIN allocation_tags  AS t4 ON t4.id = t1.allocation_tag_id
   LEFT JOIN send_assignments AS t2 ON t2.assignment_id = t1.id AND t2.user_id = #{students_id}
   LEFT JOIN assignment_files AS t3 ON t3.send_assignment_id = t2.id
       WHERE t4.group_id = #{groups_id}
       GROUP BY t1.id, t1.name, t1.start_date, t1.end_date, t2.id, t2.grade
       ORDER BY t1.end_date;
SQL
    return (assignments.nil?) ? [] : assignments
  end

end

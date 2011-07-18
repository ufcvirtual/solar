class PortfolioProfessorController < ApplicationController

  before_filter :require_user
  before_filter :curriculum_unit_name

  # lista de portfolio dos alunos de uma turma
  def list

    authorize! :list, PortfolioProfessor

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

    # recupera turma selecionada
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    @students_id = params[:id]
    @activities = Assignment.joins(:allocation_tag, :send_assignments).
      select("name, start_date, end_date").
      where("allocation_tags.group_id = ?", groups_id)

# @activities = Assignment.includes(:allocation_tag, :send_assignments).
#      where("allocation_tags.group_id = ?", groups_id)



#    SELECT t1.id, t1.allocation_tag_id, t1.name, t1.start_date, t1.end_date
#      FROM assignments AS t1
#      JOIN send_assignments AS t2 ON t2.assignment_id = t1.id
#      JOIN allocation_tags AS t3 ON t3.id = t1.allocation_tag_id
#      WHERE t3.group_id = 3;


  end

  # detalha o portfolio do aluno para a turma em questao
  def student_detail

    authorize! :student_detail, PortfolioProfessor

    @send_assignment_id = params[:send_assignment_id]
    @students_id = params[:id]

    # recuperar o nome da atividade
    activity = Assignment.joins(:send_assignments).where("send_assignments.id = ? AND user_id = ?", @send_assignment_id, @students_id)
    @activity = ''
    @activity = activity.first["name"] unless activity.first.nil?

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

    authorize! :update_comment, PortfolioProfessor

    comments, grade, comment, send_assignment_id, students_id = nil, nil, nil, nil, nil
    comments = params[:comments] if params.include? :comments

    # recupera valores do formulario
    if comments.include? :grade
      grade = comments[:grade].to_f unless comments[:grade].nil? || comments[:grade] == ''
    end

    comment = comments[:comment] if comments.include? :comment

    # atividade em questao
    send_assignment_id = params[:send_assignment_id] if params.include? :send_assignment_id

    # usuarios envolvidos
    students_id = params[:students_id] if params.include? :students_id
    professors_id = current_user.id

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

    redirect = {:action => :student_detail, :id => students_id, :send_assignment_id => send_assignment_id}

    respond_to do |format|

      begin

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

  # deleta arquivos enviados
  def delete_file

    authorize! :delete_file, PortfolioProfessor

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

    authorize! :upload_files, PortfolioProfessor

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

    authorize! :download_files_student, PortfolioProfessor

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

=begin
  # lista de alunos por turma
  def list_of_students_by_group(group_id)
    ActiveRecord::Base.connection.select_all <<SQL
      SELECT t5.id, t5.name
        FROM groups           AS t1
        JOIN allocation_tags  AS t2 ON t2.group_id = t1.id
        JOIN allocations      AS t3 ON t3.allocation_tag_id = t2.id
        JOIN profiles         AS t4 ON t4.id = t3.profile_id
        JOIN users            AS t5 ON t5.id = t3.user_id
       WHERE t4.student = TRUE
         AND t1.id = #{group_id}
       ORDER BY t5.name;
SQL
  end
=end

end

class PortfolioProfessorController < ApplicationController

  before_filter :require_user
  before_filter :curriculum_unit_name

  # lista de portfolio dos alunos de uma turma
  def list

    group_id = 3 # devera ser carregado a partir da escolha da combo de GROUP

    # lista dos alunos da turma
    @students = list_of_students_by_group(group_id)

  end

  # detalha o portfolio do aluno para a turma em questao
  def student_detail

    # modificar esta opcao
    send_assignment_id = 2
    students_id = params[:id]

    # recuperar o nome da atividade
    activity = Assignment.joins(:send_assignments).where("send_assignments.id = ? AND user_id = ?", send_assignment_id, students_id)
    @activity = ''
    @activity = activity.first["name"] unless activity.nil?

    # estudante
    @student = User.select("name").where(["id = ?", students_id]).first

    # arquivos enviados pelo aluno e nota
    @grade = ''
    @files = AssignmentFile.includes(:send_assignment).where("assignment_files.send_assignment_id = ? AND send_assignments.user_id = ?", send_assignment_id, students_id)
    @grade = @files.first.send_assignment["grade"] unless @files.nil?
    @files = [] if @files.nil?

    # comentarios e arquivos do professor
    @comments_files = CommentFile.includes(:assignment_comment).where("assignment_comments.send_assignment_id = ?", send_assignment_id)
    @comment = @comments_files.first.assignment_comment["comment"] unless @comments_files.nil?

  end

  # deleta arquivos enviados
  def delete_file

  end

  # atualiza comentarios do professor
  def update_comment
    
  end

  # upload de arquivos para o comentario
  def upload_files

  end

  private

  # recupera o nome do curriculum_unit
  def curriculum_unit_name
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"] # recupera unidade curricular da sessao
    @curriculum_unit = CurriculumUnit.select("id, name").where(["id = ?", curriculum_unit_id]).first
  end

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

end

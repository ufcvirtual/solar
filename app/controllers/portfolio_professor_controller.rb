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
    student_id = params[:id] || 0

    # estudante
    @student = User.select("name").where(["id = ?", student_id]).first


#    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
#
#    # arquivos enviados
#    CommentFile.select("attachment_file_name, attachment_update_at").where(["assignment_comment_id = ?", assignment_comment_id])


    # nota

    # comentarios

    # anexos aos comentarios

  end

  # deleta arquivos enviados
  def delete_file
    
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

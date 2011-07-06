class PortfolioProfessorController < ApplicationController

  # lista de portfolio dos alunos de uma turma
  def list

    # unidade curricular
    @curriculum_unit = CurriculumUnit.find(params[:id])

    group_id = 3 # devera ser carregado a partir da escolha da combo de GROUP

    # lista dos alunos da turma
    @students = list_of_students_group_by_teacher_and_group(group_id)

  end

  # detalha o portfolio do aluno para a turma em questao
  def student_detail
    
  end

  private

  # lista de alunos por turma
  def list_of_students_group_by_teacher_and_group(group_id)
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

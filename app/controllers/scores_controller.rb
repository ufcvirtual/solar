class ScoresController < ApplicationController

  before_filter :require_user

  # lista informacoes de acompanhamento do aluno
  def index

    # recupera turma selecionada
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    student_id = current_user.id

    @student = User.find(student_id)
    @activities = PortfolioTeacher.list_assignments_by_group_and_student(group_id, student_id)

  end

end

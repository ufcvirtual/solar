class ScoresController < ApplicationController

  before_filter :require_user

  include PortfolioTeacherHelper

  # lista informacoes de acompanhamento do aluno
  def index

    # recupera turma selecionada
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    students_id = current_user.id

    @student = User.find(students_id)
    @activities = list_assignments_by_group_and_student(groups_id, students_id)

  end

end

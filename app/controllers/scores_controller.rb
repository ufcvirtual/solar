class ScoresController < ApplicationController

  before_filter :require_user

  # Lista informacoes de acompanhamento do aluno
  def index

    authorize! :index, Score

    # recupera turma selecionada
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # se o aluno nao for passado como parametro, o usuario logado sera considerado como um
    student_id = (params.include?('student_id')) ? params[:student_id] : current_user.id # verificar se isso pode ser feito

    student = User.find(student_id)

    # verifica se o usuario logado tem permissao para consultar o usuario informado
    authorize! :find, student

    @student = student
    @activities = PortfolioTeacher.list_assignments_by_group_and_student(group_id, student_id)
    @discussions = Discussion.all_by_group_and_student_id(group_id, student_id)

  end

end

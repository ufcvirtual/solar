class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:show]

  ##
  # Lista informacoes de acompanhamento do aluno
  ##
  def show
    authorize! :show, Score

    student_id = params[:student_id] || current_user.id
    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    allocations = AllocationTag.find_related_ids(allocation_tag_id)

    # verifica se o usuario logado tem permissao para consultar o usuario informado
    student = User.find(student_id)

    # verifica autorizacao para consultar dados do usuario
    authorize! :find, student

    @student = student
    @activities = PortfolioTeacher.list_assignments_by_allocations_and_student_id(allocations, student_id)
    @discussions = Discussion.all_by_allocations_and_student_id(allocations, student_id)

    from_date = Date.today << 2 # dois meses atras
    until_date = Date.today
    @amount = Score.find_amount_access_by_student_id_and_interval(active_tab[:url]['id'], @student.id, from_date, until_date)

  end

  ##
  # Quantidade de acessos do aluno a unidade curricular
  ##
  def amount_history_access

    @from_date = params['from-date']
    @until_date = params['until-date']
    @student_id = params[:id]
    curriculum_unit_id = active_tab[:url]["id"]

    # validar as datas
    @from_date = date_valid?(@from_date) ? Date.parse(@from_date) : Date.today << 2
    @until_date = date_valid?(@until_date) ? Date.parse(@until_date) : Date.today

    @amount = Score.find_amount_access_by_student_id_and_interval(curriculum_unit_id, @student_id, @from_date, @until_date)

    render :layout => false

  end

  ##
  # Historico de acesso do aluno
  ##
  def history_access

    from_date = params['from-date']
    until_date = params['until-date']
    student_id = params['id']
    curriculum_unit_id = active_tab[:url]["id"]

    # validar as datas
    from_date = Date.today << 2 unless date_valid?(@from_date)
    until_date = Date.today unless date_valid?(@until_date)

    @history = Score.history_student_id_and_interval(curriculum_unit_id, student_id, from_date, until_date)

    render :layout => false

  end

  private

  ##
  # Verifica se a data tem um formato valido
  ##
  def date_valid?(date)
    begin
      return true if Date.parse date
    rescue
      return false
    end
  end

end

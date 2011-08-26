class ScoresController < ApplicationController

  before_filter :require_user
  before_filter :prepare_for_group_selection, :only => [:show]

  # Lista informacoes de acompanhamento do aluno
  def show

    authorize! :show, Score

    # recupera turma selecionada
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # se o aluno nao for passado como parametro, o usuario logado sera considerado como um
    student_id = (params.include?('student_id')) ? params[:student_id] : current_user.id # verificar se isso pode ser feito
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]

    begin

      # verifica se o usuario logado tem permissao para consultar o usuario informado
      student = User.find(student_id)

      # verifica autorizacao para consultar dados do usuario
      authorize! :find, student

      # verifica se o id passado é de um perfil de estudante
      raise :invalid_identifier unless Profile.student?(student_id)

      @student = student
      @activities = PortfolioTeacher.list_assignments_by_group_and_student_id(group_id, student_id)
      @discussions = Discussion.all_by_group_id_and_student_id(group_id, student_id)

      from_date = Date.today << 2 # dois meses atras
      until_date = Date.today
      @amount = Score.find_amount_access_by_student_id_and_interval(curriculum_unit_id, @student.id, from_date, until_date)

    rescue Exception => except
      respond_to do |format|

        flash[:error] = t(:invalid_identifier)
        format.html {redirect_to({:controller => :users, :action => :mysolar})}

      end
    end

  end

  # Quantidade de acessos do aluno a unidade curricular
  def amount_history_access

    @from_date = params['from-date']
    @until_date = params['until-date']
    @student_id = params[:id]
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]

    # validar as datas
    @from_date = Date.today << 2 unless date_valid?(@from_date)
    @until_date = Date.today unless date_valid?(@until_date)

    @amount = Score.find_amount_access_by_student_id_and_interval(curriculum_unit_id, @student_id, @from_date, @until_date)

    render :layout => false

  end

  # Historico de acesso do aluno
  def history_access

    from_date = params['from-date']
    until_date = params['until-date']
    @student_id = params['student_id']
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]

    # validar as datas
    from_date = Date.today << 2 unless date_valid?(@from_date)
    until_date = Date.today unless date_valid?(@until_date)

    @history = Score.history_student_id_and_interval(curriculum_unit_id, @student_id, from_date, until_date)

    render :layout => false

  end

  private

  # Verifica se a data tem um formato valido
  def date_valid?(date)
    begin
      return true if Date.parse date
    rescue
      return false
    end
  end

end

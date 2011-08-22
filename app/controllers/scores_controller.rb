class ScoresController < ApplicationController

  before_filter :require_user

  # Lista informacoes de acompanhamento do aluno
  def show

    authorize! :show, Score

    # recupera turma selecionada
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # se o aluno nao for passado como parametro, o usuario logado sera considerado como um
    student_id = (params.include?('id')) ? params[:id] : current_user.id # verificar se isso pode ser feito

    begin

      # verifica se o usuario logado tem permissao para consultar o usuario informado
      student = User.find(student_id)

      # verifica autorizacao para consultar dados do usuario
      authorize! :find, student

      # verifica se o id passado é de um perfil de estudante
      raise :invalid_identifier unless Profile.student?(student_id)

      @student = student
      @activities = PortfolioTeacher.list_assignments_by_group_and_student_id(group_id, student_id)
      @discussions = Discussion.all_by_group_and_student_id(group_id, student_id)

    rescue
      respond_to do |format|

        flash[:error] = t(:invalid_identifier)
        format.html {redirect_to({:controller => :users, :action => :mysolar})}

      end
    end

  end

  # Quantidade de acessos do aluno a unidade curricular
  def amount_history_access

    # retorna valor direto

    render :layout => false

    respond_to do |format|
      @amount = Score.find_amount_access_by_student_id(params[:id])

      format.html
    end

  end

  # Historico de acesso do aluno
  def history_access
    render :layout => false
  end

end

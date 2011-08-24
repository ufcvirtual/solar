class ApplicationController < ActionController::Base

  # Variáveis de sessão utilizadas no sistema
  #
  #   - session[:opened_tabs]
  #   - session[:active_tab]
  #   - session[:return_to]
  #   - session[:current_page]
  #   - session[:forum_display_mode]
  #

  protect_from_forgery

  helper_method :current_user_session, :current_user

  before_filter :return_user, :application_context, :current_menu
  before_filter :log_access, :only => :add_tab

  # Mensagem de erro de permissão
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t(:no_permission)
    redirect_to :controller => "users", :action => "mysolar"
  end

  # consulta id relacionado a estudante na tabela PROFILES
  def student_profile
    prof = Profile.find_by_student(true)
    if prof
      return prof.id
    else
      return ''
    end
  end

  # define aba ativa
  def activate_tab
    name = params[:name]
    session[:active_tab] = name

    unless session[:opened_tabs].nil?
      # redireciona de acordo com o tipo de aba ativa
      if session[:opened_tabs][name]["type"] == Tab_Type_Home
        redirect_to :controller => "users", :action => "mysolar"
      end
      if session[:opened_tabs][name]["type"] == Tab_Type_Curriculum_Unit
        redirect_to :controller => 'curriculum_units', :action => 'access', :id => session[:opened_tabs][name]["id"], :groups_id => session[:opened_tabs][name]["groups_id"], :offers_id => session[:opened_tabs][name]["offers_id"]
      end
    else
      redirect_to :controller => "users", :action => "mysolar"
    end
  end

  # fecha aba
  def close_tab
    name = params[:name]

    # se aba que vai fechar é a ativa, manda pra aba home
    if session[:active_tab] == name
      session[:active_tab] = 'Home'
    end

    # remove do hash
    session[:opened_tabs].delete(name)

    # redireciona de acordo com o tipo de aba ativa
    if session[:opened_tabs][session[:active_tab]]["type"] == Tab_Type_Home
      redirect_to :controller => "users", :action => "mysolar"
    end
    if session[:opened_tabs][session[:active_tab]]["type"] == Tab_Type_Curriculum_Unit
      redirect_to :controller => 'curriculum_units', :action => 'access', :id => session[:opened_tabs][session[:active_tab]]["id"]
    end
  end

  def return_user
    @user = User.find(current_user.id) unless current_user.nil?
  end

  # recupear o contexto que esta sendo acessado
  def application_context
    @context, @context_param_id = nil, nil

    # recupera o contexto do controller que esta sendo acessado
    query = "  SELECT DISTINCT t3.name AS context
                 FROM resources AS t1
                 JOIN menus     AS t2 ON t1.id = t2.resource_id
                 JOIN contexts  AS t3 ON t3.id = t2.context_id
                WHERE t1.controller = '#{params[:controller]}';"

    context = ActiveRecord::Base.connection.select_all query

    @context = context[0]["context"] if context.length > 0
    # recupera o curriculum unit da sessao do usuario, com a tab ativa
    @context_param_id = session[:opened_tabs][session[:active_tab]]["id"] if session.include?("opened_tabs") && session[:opened_tabs][session[:active_tab]].include?("id")

  end

  # Adiciona uma aba no canto superior da interface
  def add_tab

    name_tab = params[:name]
    type = params[:type] # tipo de aba -> Home ou Curriculum_Unit
    id = params[:id]
    groups_id = params[:groups_id]
    offers_id = params[:offers_id]

    # se hash nao existe, cria
    session[:opened_tabs] = Hash.new if session[:opened_tabs].nil?

    # se estourou numero de abas, volta para mysolar
    redirect = {:controller => :users, :action => :mysolar} # Tab_Type_Home

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if new_tab?(name_tab)
      hash_tab = {
        "id" => id,
        "type" => type,
        "groups_id" => groups_id,
        "offers_id" => offers_id
      }

      set_session_opened_tabs(name_tab, hash_tab)

      # redireciona de acordo com o tipo de aba
      redirect = {
        :controller => :curriculum_units,
        :action => :access,
        :id => id, :groups_id => groups_id,
        :offers_id => offers_id
      } if type == Tab_Type_Curriculum_Unit

    end

    redirect_to redirect

  end
  
  # Seta o valor do menu corrente
  def current_menu
    session[:current_menu] = params.include?('mid') ? params[:mid] : nil
  end

  private

  # Verifica se será necessário criar uma nova aba ou se ja existe uma aba aberta
  # com o mesmo nome passado como parametro
  def new_tab?(name_tab)
    return (session[:opened_tabs].length < Max_Tabs_Open.to_i) || (session[:opened_tabs].has_key?(name_tab))
  end

  # atualiza a sessao com as abas abertas e ativas
  def set_session_opened_tabs(name_tab, hash_tab)
    session[:opened_tabs][name_tab] = hash_tab
    session[:active_tab] = name_tab
  end

  # grava log de acesso a unidade curricular
  def log_access
    Log.create(:log_type => Log::TYPE[:course_access], :user_id => current_user.id, :curriculum_unit_id => params[:id]) if (params[:type] == Tab_Type_Curriculum_Unit)
  end

  def current_user_session
    #logger.debug "ApplicationController::current_user_session"

    if @current_user_session
      if params[:user_session]

        if @current_user_session.login == params[:user_session][:login]
          #logger.debug "LOGINS IGUAIS"
          return @current_user_session
        else
          #logger.debug "LOGINS DIFERENTES"
          @current_user_session.destroy
          @current_user_session = UserSession.new(params[:user_session])
          return @current_user_session
        end

      end
    end

    #return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    #logger.debug "ApplicationController::current_user"
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    #logger.debug "ApplicationController::require_user"
    unless current_user
      store_location
      flash[:notice] = t(:app_controller_require)
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    #logger.debug "ApplicationController::require_no_user"
    if current_user
      store_location
      redirect_to users_mysolar_url #account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  #definir o idioma
  before_filter :set_locale

  def set_locale
    # permitir apenas locales conhecidos
    params[:locale] = nil unless ['en', 'pt-BR'].include?(params[:locale])

    if current_user

      # recupera os dados de locale das configuracoes do usuario
      personal_options = PersonalConfiguration.find_by_user_id(current_user.id)

      # caso seja o primeiro acesso do usuario
      if personal_options.nil?
        personal_options = PersonalConfiguration.new :user_id => current_user.id
      end

      I18n.locale = params[:locale] || personal_options.default_locale || I18n.default_locale

      # se o locale for passado pela url os dados do usuario serao alterados no base de dados
      unless params[:locale].nil?
        personal_options.default_locale = params[:locale]
        personal_options.save
      end

      # caso seja a primeira sessao do usuario
      if personal_options.new_record?
        personal_options.save
      end

    else
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end

  def default_url_options(options={})
    current_user = User.new
    if current_user.nil?
      {:locale => params[:locale]} # insere locale na url se o usuario nao estiver online
    else
      {}
    end
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Preparando o uso da paginação
  def prepare_for_pagination
    @current_page = session[:current_page]
    session[:current_page] = nil

    @current_page = params[:current_page] if @current_page.nil?
    @current_page = "1" if @current_page.nil?
  end

  # Preparando para seleção genérica de turmas
  def prepare_for_group_selection
    #Colocar aqui: se session[:opened_tabs][session[:active_tab]]["groups_id"] for nulo, pega o 1o com permissao
    group_id = params[:selected_group]
   
    #Checando se ainda nao está com nenhum group_id na sessao
    if (session[:opened_tabs][session[:active_tab]]["groups_id"] == "" or session[:opened_tabs][session[:active_tab]]["groups_id"].nil?)
      group_id = CurriculumUnit.find_user_groups_by_curriculum_unit((session[:opened_tabs][session[:active_tab]]["id"]), current_user.id )[0].id
    end

    unless group_id.nil?
      session[:opened_tabs][session[:active_tab]]["groups_id"] = group_id
      session[:opened_tabs][session[:active_tab]]["offers_id"] = Group.find(group_id).offer.id
    end
  end

  def hold_pagination
    session[:current_page] = @current_page
  end

  # download de arquivos
  def download_file(redirect_error, path_, filename_, prefix_ = nil)

    # verifica se o arquivo possui prefixo
    unless prefix_.nil?
      path_file = "#{path_}/#{prefix_}_#{filename_}"
    else
      path_file = "#{path_}/#{filename_}"
    end

    #Caso o caminho do arquivo todo tenha sido passado em 'path_', desconsidera
    #o resto e descobre o filename
    if (filename_ == '')
      path_file = path_
      pattern = /\//
      filename_ = path_file[path_file.rindex(pattern)+1..-1]
    end


    if File.exist?(path_file)
      send_file path_file, :filename => filename_
    else
      respond_to do |format|
        flash[:error] = t(:error_nonexistent_file)
        format.html { redirect_to(redirect_error) }
      end
    end

  end
end


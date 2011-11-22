# Variaveis de sessao do usuario
# user_session {
#   :opened => {},
#   :active => ''
# }

# Variáveis de sessão utilizadas no sistema
# - session[:return_to]
# - session[:current_page]
# - session[:forum_display_mode]

class ApplicationController < ActionController::Base

  protect_from_forgery

  # autenticação do usuario para acessar as funcionalidades do sistema atraves do devise
  before_filter :authenticate_user!

  # BreadCrumb
  before_filter :define_second_level_breadcrumb, :only => [:activate_tab, :add_tab, :close_tab]
  before_filter :define_third_level_breadcrumb

  #helper_method :current_user_session, :current_user
  #before_filter :return_user, :application_context, :current_menu
  #before_filter :log_access, :only => :add_tab
  before_filter :set_locale


  layout :layout_by_resource

  ##
  # Verificando o layout a ser renderizado
  ##
  def layout_by_resource
    return devise_controller? ? 'login' : 'application'
  end

  # Constantes utilizadas na migalha de pao
  BreadCrumb_First_Level = 0
  BreadCrumb_Second_Level = 1
  BreadCrumb_Third_Level = 2

  # Mensagem de erro de permissão
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t(:no_permission)
    redirect_to :controller => :home
  end

  ###########################################
  # BREADCRUMB
  ###########################################

  ##
  # Setando sistema para home e atualizando breadcrumb
  ##
  def set_active_tab_to_home
    session[:active_tab] = 'Home'
    clear_breadcrumb_after(BreadCrumb_First_Level) # limpa o breadcrumb
    session[:current_menu] = nil # limpando menu acionado
  end

  ##
  # Seta os valores para o segundo nivel de breadcrumb
  ##
  def define_second_level_breadcrumb

    if params[:action] == 'close_tab'
      # se a aba a ser fechada for a atual, a migalha deve voltar para o Home
      clear_breadcrumb_after(BreadCrumb_First_Level) if session[:active_tab] == params[:name]
    else
      if params[:name] == 'Home'
        clear_breadcrumb_after(BreadCrumb_First_Level)
      else
        params.delete('authenticity_token')
        session[:breadcrumb][BreadCrumb_Second_Level] = { :name => params[:name], :url => params } if session.include?('breadcrumb')
        clear_breadcrumb_after(BreadCrumb_Second_Level)
      end
    end

  end

  ##
  # O terceiro nivel eh definido quando o usuario acessa um link do menu lateral
  ##
  def define_third_level_breadcrumb

    # verificando se a chamada vem do menu
    if params.include?('mid')

      params.delete('bread')
      params.delete('mid')

      session[:breadcrumb][BreadCrumb_Third_Level] = { :name => params[:bread], :url => params } if session.include?('breadcrumb')
    end

  end

  ##
  # Consulta id relacionado a estudante na tabela PROFILES
  ##
  def student_profile
    prof = Profile.find_by_student(true)
    return prof.id if prof
    return ''
  end

  ##
  # Define aba ativa
  ##
  def activate_tab

    session[:active_tab] = params[:name] # setando aba ativa
    session[:current_menu] = nil # removendo menu selecionado

    # verifica se existe array de abas ativas
    opened_tabs = session[:opened_tabs].nil? ? nil : (session[:opened_tabs].has_key?(params[:name]) ? session[:opened_tabs][params[:name]] : nil)

    unless opened_tabs.nil? or opened_tabs["type"] != Tab_Type_Curriculum_Unit
      redirect_to :controller => :curriculum_units, :action => :show, :id => opened_tabs["id"] #, :groups_id => opened_tabs["groups_id"], :offers_id => opened_tabs["offers_id"]
    else
      redirect_to :controller => :home
    end
  end

  ##
  # Fecha abas
  ##
  def close_tab
    tab_name = params[:name]

    user_session[:tabs][:active] = 'Home' if user_session[:tabs][:active] == tab_name
    user_session[:tabs][:opened].delete(tab_name)

    active_tab = user_session[:tabs][:opened][user_session[:active]]

    # redireciona de acordo com o tipo de aba ativa
    if !active_tab.nil? and active_tab.include?('type') and active_tab['type'] == Tab_Type_Curriculum_Unit
      redirect_to :controller => :curriculum_units, :action => :show, :id => active_tab['id']
    else
      redirect_to :controller => :home
    end
  end

  ##
  # Adiciona uma aba no canto superior da interface
  ##
  def add_tab

    name_tab, type = params[:name], params[:type] # Home ou Curriculum_Unit
    id, allocation_tag_id = params[:id], params[:allocation_tag_id]

    # se hash nao existe, cria
    user_session[:tabs] = {:opened => {}, :active => nil} unless user_session.include?(:tabs)

    # se estourou numero de abas, volta para mysolar
    redirect = {:controller => :home} # Tab_Type_Home

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if new_tab?(name_tab)
      hash_tab = {"id" => id, "type" => type, "allocation_tag_id" => allocation_tag_id}

      # atualizando dados da sessao
      set_session_opened_tabs(name_tab, hash_tab)

      # redireciona de acordo com o tipo de aba
      redirect = { :controller => :curriculum_units, :action => :show, :id => id, :allocation_tag => allocation_tag_id } if type == Tab_Type_Curriculum_Unit

    end

    redirect_to redirect

  end

  ##
  # Retorna (object)usuario logado
  ##
  def return_user
    @user = User.find(current_user.id) unless current_user.nil?
  end

  ##
  # Recupera o contexto que esta sendo acessado
  ##
  def application_context
    # considera-se por default que o usuario esta acessando o Home
    context_id = Tab_Type_Home
    active_tab = session.include?("opened_tabs") ? session[:opened_tabs][session[:active_tab]] : []

    if (!active_tab.nil? and params['action'] != 'mysolar' and params['controller'] != 'pages' and session.include?("opened_tabs") and active_tab.include?("type"))
      context_id = active_tab["type"]
    end

    @context = Context.find(context_id).name

    # recupera o curriculum unit da sessao do usuario, com a tab ativa
    @context_param_id = active_tab["id"] if session.include?("opened_tabs") and (!active_tab.nil? and active_tab.include?("id"))
  end

  ##
  # Seta o valor do menu corrente
  ##
  def current_menu
    session[:current_menu] = params[:mid] if params.include?('mid')
  end

  private

  # Define links de mesmo nivel
  def clear_breadcrumb_after(level)
    session[:breadcrumb] = session[:breadcrumb].first(level+1) unless session[:breadcrumb].nil?
  end

  ##
  # Verifica se existe uma aba criada com o nome passado
  ##
  def new_tab?(name_tab)
    return (session[:opened_tabs].length < Max_Tabs_Open.to_i) || (session[:opened_tabs].has_key?(name_tab))
  end

  ##
  # Atualiza a sessao com as abas abertas e ativas
  ##
  def set_session_opened_tabs(name_tab, hash_tab)
    # definindo dados das tabelas caso ainda nao existam
    user_session[:tabs] = {:opened => {}, :active => nil} unless user_session.include?(:tabs)

    user_session[:tabs][:opened][name_tab] = hash_tab
    user_session[:tabs][:active] = name_tab
  end

  ##
  # Grava log de acesso a unidade curricular
  ##
  def log_access
    Log.create(:log_type => Log::TYPE[:course_access], :user_id => current_user.id, :curriculum_unit_id => params[:id]) if (params[:type] == Tab_Type_Curriculum_Unit)
  end

  def current_user_session
    #logger.debug "ApplicationController::current_user_session"

    #    if @current_user_session
    #      if params[:user_session]
    #
    #        if @current_user_session.login == params[:user_session][:login]
    #          #logger.debug "LOGINS IGUAIS"
    #          return @current_user_session
    #        else
    #          #logger.debug "LOGINS DIFERENTES"
    #          @current_user_session.destroy
    #          @current_user_session = UserSession.new(params[:user_session])
    #          return @current_user_session
    #        end
    #
    #      end
    #    end
    #
    #    #return @current_user_session if defined?(@current_user_session)
    #    @current_user_session = UserSession.find
  end

  #  def current_user
  #    #logger.debug "ApplicationController::current_user"
  #    return @current_user if defined?(@current_user)
  #    @current_user = current_user_session && current_user_session.user
  #  end

  #def require_user
  #  #logger.debug "ApplicationController::require_user"
  #  unless current_user
  #    store_location
  #    flash[:notice] = t(:app_controller_require)
  #    redirect_to new_user_session_url
  #    return false
  #  end
  #end

  #def require_no_user
  #  #logger.debug "ApplicationController::require_no_user"
  #  if current_user
  #    store_location
  #    redirect_to users_mysolar_url #account_url
  #    return false
  #  end
  #end

  #def store_location
  #  session[:return_to] = request.fullpath
  #end

  def set_locale
    if current_user

      # recupera os dados de locale das configuracoes do usuario
      personal_options = PersonalConfiguration.find_by_user_id(current_user.id)

      # caso seja o primeiro acesso do usuario
      personal_options = PersonalConfiguration.new :user_id => current_user.id if personal_options.nil?

      I18n.locale = params[:locale] || personal_options.default_locale || I18n.default_locale

      # se o locale for passado pela url os dados do usuario serao alterados no base de dados
      unless params[:locale].nil?
        personal_options.default_locale = params[:locale]
        personal_options.save
      end

      # caso seja a primeira sessao do usuario
      personal_options.save if personal_options.new_record?

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
    active_tab = session.include?('opened_tabs') ? session[:opened_tabs][session[:active_tab]] : []

    if !active_tab.nil? and active_tab.include?('type') and active_tab["type"] == Tab_Type_Curriculum_Unit
      #Colocar aqui: se session[:opened_tabs][session[:active_tab]]["groups_id"] for nulo, pega o 1o com permissao
      group_id = params[:selected_group]

      #Checando se ainda nao está com nenhum group_id na sessao
      if (active_tab["groups_id"] == "" or active_tab["groups_id"].nil?)
        group_id = CurriculumUnit.find_user_groups_by_curriculum_unit((active_tab["id"]), current_user.id )[0].id
      end

      unless group_id.nil?
        session[:opened_tabs][session[:active_tab]]["groups_id"] = group_id
        session[:opened_tabs][session[:active_tab]]["offers_id"] = Group.find(group_id).offer.id
      end
    end
  end

  def hold_pagination
    session[:current_page] = @current_page
  end

end


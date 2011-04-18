class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user_session, :current_user
 
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

  # adiciona uma aba no canto superior da interface
  def add_tab
    name = params[:name]    
    type = params[:type]
    id   = params[:id]

    # se hash nao existe, cria
    if session[:opened_tabs].nil?
      session[:opened_tabs] = Hash.new
    end

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if (session[:opened_tabs].length < Max_Tabs_Open.to_i) || (session[:opened_tabs].has_key?(name))
      hash_tab = Hash.new
      hash_tab["id"] = id
      hash_tab["type"] = type
      session[:opened_tabs][name] = hash_tab
      session[:active_tab] = name

      # redireciona de acordo com o tipo de aba
      if type == Tab_Type_Home
        redirect_to :controller => "users", :action => "mysolar"
      end
      if type == Tab_Type_Curriculum_Unit
        redirect_to :controller => 'curriculum_units', :action => 'access', :id => params[:id]
      end
      
    else
      # se estourou numero de abas, volta para mysolar
      redirect_to :controller => "users", :action => "mysolar"
    end    
  end

  # define aba ativa
  def activate_tab
    name = params[:name]
    session[:active_tab] = name

    # redireciona de acordo com o tipo de aba ativa
    if session[:opened_tabs][name]["type"] == Tab_Type_Home
      redirect_to :controller => "users", :action => "mysolar"
    end
    if session[:opened_tabs][name]["type"] == Tab_Type_Curriculum_Unit
      redirect_to :controller => 'curriculum_units', :action => 'access', :id => session[:opened_tabs][name]["id"]
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
  
  private

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

end


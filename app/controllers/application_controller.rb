class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user_session, :current_user

  # consulta id relacionado a estudante na tabela PROFILES
  def student_profile
    prof = Profile.find_by_student(true)
    return prof.id
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


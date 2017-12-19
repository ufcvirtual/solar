class Devise::LoginController < Devise::SessionsController

  skip_before_filter :check_concurrent_session

  def create
    user = User.find_by_username(params[:user][:login])

    if user.nil?
      if !User::MODULO_ACADEMICO.nil?
        redirect_to login_path, alert: t('devise.failure.invalid_login_si3')
      else
        redirect_to login_path, alert: t('devise.failure.invalid_login')
      end
    else
      if user.integrated && !user.on_blacklist? && !user.selfregistration
        user.synchronize
        redirect_to login_path, alert: t("users.errors.ma.selfregistration").html_safe unless user.selfregistration
      end

      unless user.integrated && !user.on_blacklist? && !user.selfregistration
        super
        current_user.session_token = Devise.friendly_token
        user_session[:token] = current_user.session_token
        current_user.save(validate: false)
      end
    end
  rescue CanCan::AccessDenied
    # something
  rescue => error
    # something
  end

  protected

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end

  def set_flash_message!(key, kind, options = {})
    message = find_message(kind, options)
    if options[:now]
      flash.now[key] = message if message.present?
    else
      flash[key] = message if message.present?
    end
  end

end

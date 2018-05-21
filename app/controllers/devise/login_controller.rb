class Devise::LoginController < Devise::SessionsController

  skip_before_filter :check_concurrent_session

  def create
    user = User.find_by_username(params[:user][:login])
    correct_password = user.valid_password?(params[:user][:password])

    if user.nil?
      if !User::MODULO_ACADEMICO.nil?
        redirect_to login_path, alert: t('devise.failure.invalid_login_si3')
      else
        redirect_to login_path, alert: t('devise.failure.invalid_login')
      end
      return
    else
      if user.integrated && !user.on_blacklist? && !user.selfregistration
        user.synchronize
        unless user.selfregistration
          redirect_to login_path, alert: t("users.errors.ma.selfregistration").html_safe
          return
        end
      elsif user.integrated && !user.on_blacklist? && !correct_password
        user.synchronize
        user = User.find_by_username(params[:user][:login])
        correct_password = user.valid_password?(params[:user][:password])
      end

      unless correct_password
        previous_user = User.where(previous_username: params[:user][:login])
        previous_user = previous_user.collect{|puser| puser if puser.valid_password?(params[:user][:password])}
        previous_user = previous_user.compact.first
        unless previous_user.blank?
          redirect_to login_path, alert: t("users.errors.ma.changed_username", new_username: previous_user.username).html_safe
          return
        end
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

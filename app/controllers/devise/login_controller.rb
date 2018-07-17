class Devise::LoginController < Devise::SessionsController

  skip_before_filter :check_concurrent_session
  prepend_before_action :verify_user_data

  def create
    case @return
    when 1; redirect_to login_path, alert: t('devise.failure.invalid_login_si3')
    when 2; redirect_to login_path, alert: t('devise.failure.invalid_login')
    when 3; redirect_to login_path, alert: t("users.errors.ma.selfregistration").html_safe
    when 4; redirect_to login_path, alert: t("users.errors.ma.changed_username", new_username: @previous_username).html_safe
    when 5
      super
      current_user.session_token = Devise.friendly_token
      user_session[:token] = current_user.session_token
      current_user.save(validate: false)
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

  def verify_user_data
    @return = 0
    user = User.find_by_username(params[:user][:login])
    correct_password = user.valid_password?(params[:user][:password]) unless user.blank?

    if user.nil?
      @return = !User::MODULO_ACADEMICO.nil? ? 1 : 2
      return
    else
      if user.integrated && !user.on_blacklist? && !user.selfregistration
        user.synchronize
        unless user.selfregistration
          @return = 3
          return
        end
      elsif (user.integrated && !user.on_blacklist? && !correct_password)
        user.synchronize
        user = User.find_by_username(params[:user][:login])
        correct_password = user.valid_password?(params[:user][:password])
      end
      unless correct_password
        previous_user = User.where(previous_username: params[:user][:login])
        previous_user = previous_user.collect{|puser| puser if puser.valid_password?(params[:user][:password])}
        previous_user = previous_user.compact.first
        unless previous_user.blank?
          @return = 4
          @previous_username = previous_user.username
          return
        end
      end

      @return = 5 unless user.integrated && !user.on_blacklist? && !user.selfregistration
    end

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

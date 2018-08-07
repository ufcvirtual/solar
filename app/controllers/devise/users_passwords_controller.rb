class Devise::UsersPasswordsController < Devise::PasswordsController
  include SysLog::Devise

  def create
    user = User.find_by_cpf(params[:user][:cpf].delete('.-'))
    if user.blank?
      redirect_to login_path, alert: t("devise.users_passwords.not_found").html_safe
    elsif user.integrated? && !user.on_blacklist?
      user.synchronize
      user = User.find_by_cpf(params[:user][:cpf].delete('.-'))
      unless (user.selfregistration)
        redirect_to login_path, alert: t("users.errors.ma.selfregistration").html_safe
      else
        redirect_to login_path, notice: t("devise.users_passwords.ma_request").html_safe
      end
    else
      if user.email.blank?
        redirect_to login_path, notice: t("devise.users_passwords.no_email").html_safe
      else
        user.send_reset_password_instructions
        redirect_to login_path, notice: t("devise.users_passwords.send_instructions_email", email: user.email).html_safe
      end
    end
  end
end
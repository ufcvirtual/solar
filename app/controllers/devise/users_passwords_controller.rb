class Devise::UsersPasswordsController < Devise::PasswordsController
  include SysLog::Devise

  def create
    user = User.find_by_email(params[:user][:email])
    if not(user.nil?) and user.integrated?
      redirect_to login_path, notice: t("devise.users_passwords.ma_request").html_safe
    else
      super
    end
  end
end
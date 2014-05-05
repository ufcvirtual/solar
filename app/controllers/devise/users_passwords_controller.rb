class Devise::UsersPasswordsController < Devise::PasswordsController

  include SysLog::Devise

  def update
    super
  end

  def create
    super
  end

end
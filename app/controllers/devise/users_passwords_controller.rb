class Devise::UsersPasswordsController < Devise::PasswordsController
  include SysLog::Devise
end
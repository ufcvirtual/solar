class SessionsController < Devise::SessionsController
  def create
    respond_to do |format|
      format.html { super }

      format.xml {
        warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
        current_user.reset_authentication_token! # modifica o token do usuario ao realizar uma autenticacao
        render :status => 200, :xml => { :session => { :error => "Success", :auth_token => current_user.authentication_token }}
      }
 
      format.json {
        warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
        current_user.reset_authentication_token! # modifica o token do usuario ao realizar uma autenticacao
        render :status => 200, :json => { :session => { :error => "Success", :auth_token => current_user.authentication_token } }
      }
    end
  end
end

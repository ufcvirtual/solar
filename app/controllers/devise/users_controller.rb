class Devise::UsersController < Devise::RegistrationsController

  def create
    build_resource(sign_up_params)

    user_cpf       = params[:user][:cpf].delete('.').delete('-')
    resource.cpf   = user_cpf
    resource_saved = resource.save
    tmp_email      = [user_cpf, YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]["tmp_email_provider"]].join("@")
    warning        = I18n.t("users.errors.ma.login_email") if resource.email == tmp_email and resource.username == "#{user_cpf}"

    yield resource if block_given?
    if resource_saved
      if resource.active_for_authentication?
        set_flash_message (warning ? :warning : :notice), (warning ? warning : :signed_up)
        sign_up(resource_name, resource)
        redirect_to after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" # if is_navigational_format? #is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  protected

    def after_sign_up_path_for(resource)
      LogAction.new_user(user_id: resource.id, ip: request.remote_ip)
      super
    end

  private

    def sign_up_params
      params.require(:user).permit(:username, :email, :email_confirmation, :alternate_email, :password, :password_confirmation,
        :remember_me, :name, :nick, :birthdate, :address, :address_number, :address_complement, :address_neighborhood,
        :zipcode, :country, :state, :city, :telephone, :cell_phone, :institution, :gender, :cpf, :bio, :interests, :music,
        :movies, :books, :phrase, :site, :photo, :special_needs, :active)
    end

    def account_update_params
      params.require(:user).permit(:username, :email, :email_confirmation, :alternate_email, :current_password, :password,
        :password_confirmation, :remember_me, :name, :nick, :birthdate, :address, :address_number, :address_complement,
        :address_neighborhood, :zipcode, :country, :state, :city, :telephone, :cell_phone, :institution, :gender, :cpf,
        :bio, :interests, :music, :movies, :books, :phrase, :site, :photo, :special_needs, :active)
    end

end

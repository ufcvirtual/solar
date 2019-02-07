class Devise::UsersController < Devise::RegistrationsController
  before_action :load_deficiencys

  def create
    build_resource(sign_up_params)

    user_cpf       = params[:user][:cpf].delete('.').delete('-')
    resource.cpf   = user_cpf
    resource_saved = resource.save
    warning        = I18n.t("users.errors.ma.login_email") if resource.email.blank? && resource.username == "#{user_cpf}"

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

  def update
    set_current_user
    super
  end

  protected

    def after_sign_up_path_for(resource)
      LogAction.new_user(user_id: resource.id, ip: get_remote_ip)
      super
    end

  private

    def load_deficiencys
      @special_needs = [[t('deficiency.none'), nil],
      [t('deficiency.autism_complete'), t('deficiency.code.autism')], 
      [t('deficiency.low_vision_complete'), t('deficiency.code.low_vision')],
      [t('deficiency.blindness_complete'), t('deficiency.code.blindness')],
      [t('deficiency.hearing_deficiency_complete'), t('deficiency.code.hearing_deficiency')],
      [t('deficiency.physical_disability_complete'), t('deficiency.code.physical_disability')],
      [t('deficiency.intellectual_deficiency_complete'), t('deficiency.code.intellectual_deficiency')],
      [t('deficiency.multiple_disability_complete'), t('deficiency.code.multiple_disability')],
      [t('deficiency.deafness_complete'), t('deficiency.code.deafness')],
      [t('deficiency.deafblindness_complete'), t('deficiency.code.deafblindness')],
      [t('deficiency.aspergers_syndrome_complete'), t('deficiency.code.aspergers_syndrome')],
      [t('deficiency.rett_syndrome_complete'), t('deficiency.code.rett_syndrome')],
      [t('deficiency.childhood_disintegrative_disorder_complete'), t('deficiency.code.childhood_disintegrative_disorder')],
      [t('deficiency.other'), t('deficiency.code.other')]]
    end

    def sign_up_params
      params.require(:user).permit(:username, :email, :email_confirmation, :alternate_email, :password, :password_confirmation,
        :remember_me, :name, :nick, :birthdate, :address, :address_number, :address_complement, :address_neighborhood,
        :zipcode, :country, :state, :city, :telephone, :cell_phone, :institution, :gender, :cpf, :bio, :interests, :music,
        :movies, :books, :phrase, :site, :photo, :special_needs, :active, :other_special_needs)
    end

    def account_update_params
      params.require(:user).permit(:username, :email, :email_confirmation, :alternate_email, :current_password, :password,
        :password_confirmation, :remember_me, :name, :nick, :birthdate, :address, :address_number, :address_complement,
        :address_neighborhood, :zipcode, :country, :state, :city, :telephone, :cell_phone, :institution, :gender, :cpf,
        :bio, :interests, :music, :movies, :books, :phrase, :site, :photo, :special_needs, :active, :other_special_needs)
    end

end

class PersonalConfigurationsController < ApplicationController

  include SysLog::Actions
  layout false, except: [:index]

  #Metodo invocado quando um portlet do MySolar é movido
  def set_mysolar_portlets
    portlets_sequence = params[:PortletsSequence]

    #Carregando configurações pessoais
    personal_options = PersonalConfiguration.find_by_user_id(current_user.id)
    if personal_options.nil?
      personal_options = PersonalConfiguration.new
      personal_options.user_id = current_user.id
    end

    #Salvando atualização
    personal_options.mysolar_portlets = portlets_sequence
    personal_options.save
  end

  def update
    user = current_user
    @configure = PersonalConfiguration.find(params[:id])

    if @configure.update_attributes(personal_configuration_params)
      unless user_session[:theme].blank? || !['blue','high_contrast'].include?(user_session[:theme])
        user_session[:theme] = (user_session[:theme] == 'blue' ? 'high_contrast' : 'blue')
      else
        user_session[:theme] = 'blue'
    end
      render json: {success: true, notice: t('users.configure.success.updated')}
    else
      render json: {success: false, notice: t('users.configure.error.updated')}
    end
  rescue => error
    raise "#{error}"
    request.format = :json
    raise error.class
  end

  def update_theme
    personal_configuration = PersonalConfiguration.find_by_user_id(current_user.id)

    unless user_session[:theme].blank? || !['blue','high_contrast'].include?(user_session[:theme])
      user_session[:theme] = (user_session[:theme] == 'blue' ? 'high_contrast' : 'blue')
    else
      user_session[:theme] = 'blue'
    end


    personal_configuration.update_attribute(:theme, "#{user_session[:theme]}")
    render json: {success: true, theme: "#{user_session[:theme]}"}
  end

  private

    def personal_configuration_params
      params.require(:personal_configuration).permit(:message, :post, :exam, :theme, :academic_tool)
    end

end

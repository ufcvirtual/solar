class PersonalConfigurationsController < ApplicationController

  #Metodo invocado quando um portlet do MySolar é movido
  def set_mysolar_portlets

    portlets_sequence = params[:PortletsSequence]
    
    #Carregando configurações pessoais
    personal_options = PersonalConfiguration.find_by_user_id(current_user.id)
    if personal_options.nil?
      personal_options = PersonalConfiguration.new()
      personal_options.user_id = current_user.id
    end

    #Salvando atualização
    personal_options.mysolar_portlets = portlets_sequence
    personal_options.save()
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
  
end

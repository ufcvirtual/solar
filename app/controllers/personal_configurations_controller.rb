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
    Rails.logger.info "\n\n#{user_session[:theme]}\n\n"
    personal_configuration = PersonalConfiguration.find_by_user_id(current_user.id)
    unless user_session[:theme].blank? || !['blue','high_contrast'].include?(user_session[:theme])
      Rails.logger.info "\n\nentrou na condição\n\n"
      if user_session[:theme] == 'blue'
        user_session[:theme] = 'high_contrast'
      elsif user_session[:theme] == 'high_contrast'
        user_session[:theme] = 'blue'
      end
      Rails.logger.info "\n\n#{user_session[:theme]}\n\n\n"
      personal_configuration.update_attribute(:theme, "#{user_session[:theme]}")
      render json: {success: true, theme: "#{user_session[:theme]}"}
    end
  end
  
end

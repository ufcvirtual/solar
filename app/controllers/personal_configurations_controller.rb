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
    Rails.logger.info
    personal_configuration = PersonalConfiguration.find_by_user_id(current_user.id)
    unless params[:theme].blank? || !['blue','high_contrast'].include?(params[:theme])
      Rails.logger.info
      personal_configuration.update_attribute(:theme, params[:theme])
      render json: {success: true}
    end
  end
  
end

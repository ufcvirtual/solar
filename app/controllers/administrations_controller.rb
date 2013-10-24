class AdministrationsController < ApplicationController

  layout false, except: [:manage_user]

	# GET /administrations/manage_user
  # GET /administrations/manage_user.json
  def manage_user
    #verifica permissao
    #authorize! :manage_user

    @types = Array.new(2,4)
    @types = [ [t(".name"), '0'], [t(".email"), '1'], [t(".username"), '2'], [t(".cpf"), '3'] ]
  end

  # Método chamado por ajax para buscar usuários
  def search_users
  	type_search = params[:type_search]
    @text_search = URI.unescape(params[:user]) unless params[:user].nil?

    case type_search
      when "0"
        @users = User.where("lower(name) ~ '#{@text_search.downcase}'").paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
      when "1"
        @users = User.where("lower(email) ~ '#{@text_search.downcase}'").paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
      when "2"
        @users = User.where("lower(username) ~ '#{@text_search.downcase}'").paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
      else
        @users = User.where("lower(cpf) ~ '#{@text_search.downcase}'").paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
    end

  end

  def allocations_user
    id = params[:id]
    @allocations_user = Allocation.find_by_user_id(id) unless id.nil?
  end

  def edit_user
  end

  def change_password
  end

end
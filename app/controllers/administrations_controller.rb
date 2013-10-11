class AdministrationsController < ApplicationController

  layout false, only: [:search_users]

	# GET /administrations/manage_user
  # GET /administrations/manage_user.json
  def manage_user
    #verifica permissao
    #authorize! :manage_user

    @types = Array.new(2,4)
    @types = [ ['nome', '0'], ['email', '1'], ['login', '2'], ['cpf', '3'] ]
  end

  # Método chamado por ajax para buscar usuários
  def search_users
  	@type_search = params[:type_search]
    @text_search = URI.unescape(params[:user]) unless params[:user].nil?

    case @text_search
      when 0
        @users = User.where("lower(name) ~ '#{@type_search.downcase}'")
      when 1
        @users = User.where("lower(email) ~ '#{@type_search.downcase}'")
      when 2
        @users = User.where("lower(username) ~ '#{@type_search.downcase}'")
      else
        @users = User.where("lower(cpf) ~ '#{@type_search.downcase}'")
    end
  end

end
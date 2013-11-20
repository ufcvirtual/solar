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

    unless @text_search.nil?
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
  end

  def allocations_user
    id = params[:id]
    @allocations_user = User.find(id).allocations
                          .joins("LEFT JOIN allocation_tags at ON at.id = allocations.allocation_tag_id")
                          .where("(at.curriculum_unit_id is not null or at.offer_id is not null or at.group_id is not null )")

    @profiles = @allocations_user.map(&:profile).flatten.uniq

    @periods = [ [t(:active),''] ]
    @periods += Semester.all().map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
  end

  def show_allocation
    @allocation = Allocation.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @allocation}
    end
  end

  def edit_allocation
    @allocation = Allocation.find(params[:id])
  end

  def update_allocation
    @allocation = Allocation.find(params[:id])
    @allocation.update_attribute(:status, params[:status])

    respond_to do |format|
      format.html { render action: :show_allocation, id: params[:id] }
      format.json { render json: {status: "ok"}  }
    end
  end

  def show_user
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  def edit_user
    @user = User.find(params[:id])
  end

  def update_user
    @user = User.find(params[:id])
    active = (params[:status]=="1") ? true : false
    @user.update_attributes(active: active, name: params[:name], email: params[:email])
    respond_to do |format|
      format.json { render json: {status: "ok"}  }
    end
  end

  def change_password
    begin
      @user = User.find(params[:id]).send_reset_password_instructions
      respond_to do |format|
        format.json { render json: {status: "ok"}  }
      end
    rescue
      respond_to do |format|
        format.json { render json: {success: false}  }
      end 
    end
  end

end
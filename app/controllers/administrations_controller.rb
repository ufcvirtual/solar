class AdministrationsController < ApplicationController
  layout false, except: [:manage_user, :manage_profiles]

  ## USERS

  def manage_user
    authorize! :manage_user, Administration
    @types = Array.new(2,4)
    @types = [ [t(".name"), '0'], [t(".email"), '1'], [t(".username"), '2'], [t(".cpf"), '3'] ]
  end

  # Método chamado por ajax para buscar usuários
  def search_users
    begin
      authorize! :search_users, Administration
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
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def show_user
    begin
      authorize! :show_user, Administration
      @user = User.find(params[:id])
      respond_to do |format|
        format.html
        format.json { render json: @user }
      end
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def edit_user
    begin
      authorize! :edit_user, Administration
      @user = User.find(params[:id])
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def update_user
    begin 
      authorize! :update_user, Administration
      @user = User.find(params[:id])
      active = (params[:status]=="1") ? true : false
      @user.update_attributes(active: active, name: params[:name], email: params[:email])
      render json: {status: "ok"}
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def change_password
    begin
      authorize! :change_password, Administration
      @user = User.find(params[:id])

      Thread.new do
        Mutex.new.synchronize do
          @user.send_reset_password_instructions
        end
      end

      render json: {status: "ok", notice: t("administrations.success.email_sent")}
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    rescue
      render json: {success: false, alert: t("administrations.success.email_not_sent")}
    end
  end


  ## ALLOCATIONS


  def allocations_user
    begin
      authorize! :allocations_user, Administration
      @allocations_user = User.find(params[:id]).allocations
                            .joins("LEFT JOIN allocation_tags at ON at.id = allocations.allocation_tag_id")
                            .where("(at.curriculum_unit_id is not null or at.offer_id is not null or at.group_id is not null )")

      @profiles = @allocations_user.map(&:profile).flatten.uniq

      @periods = [ [t(:active),''] ]
      @periods += Semester.all.map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def show_allocation
    begin
      authorize! :show_allocation, Administration
      @allocation = Allocation.find(params[:id])
      respond_to do |format|
        format.html
        format.json { render json: @allocation}
      end
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def edit_allocation
    begin
      authorize! :edit_allocation, Administration
      @allocation = Allocation.find(params[:id])
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def update_allocation
     begin 
      authorize! :update_allocation, Administration
      @allocation = Allocation.find(params[:id])
      @allocation.update_attribute(:status, params[:status])

      respond_to do |format|
        format.html { render action: :show_allocation, id: params[:id] }
        format.json { render json: {status: "ok"}  }
      end
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

end
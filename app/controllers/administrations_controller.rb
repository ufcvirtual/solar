class AdministrationsController < ApplicationController

  layout false, except: [:users, :users_indication]

  ## USERS

  def users
    authorize! :users, Administration

    @types = [ [t(".name"), 'name'], [t(".email"), 'email'], [t(".username"), 'username'], [t(".cpf"), 'cpf'] ]
  end

  # Método chamado por ajax para buscar usuários
  def search_users
    begin
      authorize! :users, Administration

      type_search = params[:type_search]
      @text_search = URI.unescape(params[:user]) unless params[:user].nil?
      @users = User.where("lower(#{type_search}) ~ '#{@text_search.downcase}'").paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page) unless @text_search.nil?
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def show_user
    begin
      authorize! :update_user, Administration

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
      authorize! :update_user, Administration
      @user = User.find(params[:id])
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def update_user
    begin 
      authorize! :update_user, Administration

      @user = User.find(params[:id])
      if @user.update_attributes(params[:data])
        render json: {success: true}, status: :ok
      else
        render json: {success: false, alert: @user.errors.full_messages.uniq.compact}, status: :unprocessable_entity
      end

    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def reset_password_user
    begin
      authorize! :reset_password_user, Administration
      @user = User.find(params[:id])

      Thread.new do
        Mutex.new.synchronize do
          @user.send_reset_password_instructions
        end
      end

      render json: {success: true, notice: t("administrations.success.email_sent")}
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
      authorize! :update_allocation, Administration
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
      authorize! :update_allocation, Administration
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

  ## INDICATION USERS

  def users_indication
    authorize! :users_indication, Administration
    @types = CurriculumUnitType.all
  end

end

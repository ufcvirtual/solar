class AdministrationsController < ApplicationController

  include SysLog::Devise
  include SysLog::Actions

  layout false, except: [:users, :users_indication, :allocation_approval, :lessons]

  ## USERS

  def users
    authorize! :users, Administration

    @types = [ [t(".name"), 'name'], [t(".email"), 'email'], [t(".username"), 'username'], [t(".cpf"), 'cpf'] ]
  end

  # Método chamado por ajax para buscar usuários
  def search_users
    begin
      authorize! :users, Administration

      @type_search = params[:type_search]
      @text_search = URI.unescape(params[:user]) unless params[:user].nil?
      @users = User.where("lower(#{@type_search}) ~ '#{@text_search.downcase}'").paginate(page: params[:page], per_page: 100)

    respond_to do |format|
      format.html
      format.js
    end
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
    authorize! :allocations_user, Administration
    @allocations_user = User.find(params[:id]).allocations.joins(:profile).where("NOT cast(profiles.types & #{Profile_Type_Basic} as boolean)")
    @profiles = @allocations_user.map(&:profile).flatten.uniq
    @periods  = [ [t(:active),''] ]
    @periods += Semester.all.map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def show_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @allocation}
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edit_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def update_allocation
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

  ## INDICATION USERS

  def users_indication
    authorize! :users_indication, Administration
    @types = CurriculumUnitType.all
  end

  ## ALLOCATION APPROVAL
  require 'will_paginate/array'
  def allocation_approval
    authorize! :allocation_approval, Administration
    @allocations = Allocation.pending

    if params.include?(:search)
      @text_search, @type_search = params[:value], params[:type]
      @allocations = case @type_search
      when "name";    @allocations.joins(:user).where("lower(users.name) ~ ?", @text_search.downcase)
      when "profile"; @allocations.joins(:profile).where("lower(profiles.name) ~ ?", @text_search.downcase)
      when "curriculum_unit_type"
        @allocations.collect do |allocation|
          uc = allocation.curriculum_unit_related
          allocation if not(uc.nil?) and uc.curriculum_unit_type.description.downcase.include? @text_search.downcase
        end
      when "course"
        @allocations.collect do |allocation|
          course = allocation.course_related
          allocation if not(course.nil?) and course.name.downcase.include? @text_search.downcase
        end
      when "curriculum_unit"
        @allocations.collect do |allocation|
          uc = allocation.curriculum_unit_related
          allocation if not(uc.nil?) and uc.curriculum_unit.name.downcase.include? @text_search.downcase
        end
      when "semester"
        @allocations.collect do |allocation|
          semester = allocation.semester_related
          allocation if not(semester.nil?) and semester.name.downcase.include? @text_search.downcase
        end
      when "group"; @allocations.joins(:group).where("lower(groups.code) ~ ?", @text_search.downcase)
      else @allocations
      end
    end

    # if user isn't an admin, remove unrelated allocations
    @allocations = Allocation.remove_unrelated_allocations(current_user, @allocations) unless current_user.is_admin?

    @allocations.compact!
    @allocations = @allocations.paginate(page: params[:page], per_page: 100)
    @types = [ [t("administrations.allocation_approval.name"), 'name'], [t("administrations.allocation_approval.profile"), 'profile'], 
      [t("administrations.allocation_approval.type"), 'curriculum_unit_type'], [t("administrations.allocation_approval.course"), 'course'], 
      [t("administrations.allocation_approval.curriculum_unit"), 'curriculum_unit'], [t("administrations.allocation_approval.semester"), 'semester'], 
      [t("administrations.allocation_approval.group"), 'group'] ]

    respond_to do |format|
      format.html { render layout: false if params.include?(:search) }
      format.json { render json: @allocations }
      format.js
    end
  end

  ## Lessons
  def lessons
    authorize! :lessons, Administration
    @types = CurriculumUnitType.all
  end

end

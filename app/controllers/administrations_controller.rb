class AdministrationsController < ApplicationController

  include FilesHelper
  include SysLog::Devise
  include SysLog::Actions

  layout false, except: [:users, :users_indication, :allocation_approval, :lessons, :logs, :import_users, :responsibles]

  ## USERS

  def users
    authorize! :users, Administration

    @types = [ [t(".name"), 'name'], [t(".email"), 'email'], [t(".username"), 'username'], [t(".cpf"), 'cpf'] ]
  end

  def search_users
    authorize! :users, Administration

    @type_search = params[:type_search]
    @text_search = [URI.unescape(params[:user]).split(" ").compact.join(":*&"), ":*"].join unless params[:user].blank?
    @users    = User.where("to_tsvector('simple', unaccent(#{@type_search})) @@ to_tsquery('simple', unaccent(?))", @text_search).paginate(page: params[:page])
    @is_admin = current_user.is_admin?

    respond_to do |format|
      format.html
      format.js
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def show_user
    authorize! :update_user, Administration

    @user, @is_admin = User.find(params[:id]), current_user.is_admin?

    respond_to do |format|
      format.html { render partial: "user", locals: {user: @user} }
      format.json { render json: @user }
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edit_user
    authorize! :update_user, Administration
    @user = User.find(params[:id])
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def update_user
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

  def reset_password_user
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

  ## ALLOCATIONS

  def allocations_user
    authorize! :allocations_user, Administration

    @allocations_user = User.find(params[:id]).allocations.joins(:profile).where("NOT cast(profiles.types & ? as boolean)", Profile_Type_Basic)
    @profiles = @allocations_user.map(&:profile).flatten.uniq
    @periods  = [ [t(:active),''] ]
    @periods += Semester.all.map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
    @is_admin = current_user.is_admin?
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
      @text_search, @type_search = URI.unescape(params[:value]), params[:type]

      @allocations = case @type_search
      when "name"
        if @text_search.blank?
          @allocations.joins(:user)
        else
          text = [@text_search.split(" ").compact.join(":*&"), ":*"].join
          @allocations.joins(:user).where("to_tsvector('simple', unaccent(users.name)) @@ to_tsquery('simple', unaccent(?))", text)
        end
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
    @allocations = @allocations.paginate(page: params[:page])
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

  ## LOGS

  def logs
    authorize! :logs, Administration

    @types = [ [t(:actions, scope: [:administrations, :logs]), 'actions'], [t(:accesses, scope: [:administrations, :logs]), 'access'] ]
  end

  def search_logs
    authorize! :logs, Administration

    @logs = []
    date = Date.parse(params[:date]) rescue Date.today
    log  = params[:type] == 'actions' ? LogAction : LogAccess

    text_search = [URI.unescape(params[:user]).split(" ").compact.join(":*&"), ":*"].join unless params[:user].blank?
    user_ids = User.where("to_tsvector('simple', unaccent(name || ' ' || cpf)) @@ to_tsquery('simple', unaccent(?))", text_search).map(&:id).join(',')

    unless user_ids.blank?
      query = []
      query << "user_id IN (#{user_ids})"
      query << "date(created_at) = '#{date.to_s}'"

      @logs = log.where(query.join(" AND ")).order("created_at DESC").last(100)
    end
  end

  ## IMPORT USERS

  # GET /import/users/filter
  def import_users
    authorize! :import_users, Administration

    @types = CurriculumUnitType.all
  end

  # GET /import/users/form
  def import_users_form
    authorize! :import_users, Administration

    @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id].split(" ")).map(&:id)
  end

  # POST /import/users/batch
  def import_users_batch
    authorize! :import_users, Administration

    raise t(:invalid_file, scope: [:administrations, :import_users]) if (file = params[:batch][:file]).nil?

    delimiter = [';', ','].include?(params[:batch][:delimiter]) ? params[:batch][:delimiter] : ';'
    result = User.import(file, delimiter)
    users = result[:imported]
    @log = result[:log]
    @count_imported = result[:log][:success].count

    users.each do |user|
      params[:allocation_tags_ids].split(' ').compact.uniq.map(&:to_i).each do |at|
        begin
          AllocationTag.find(at).group.allocate_user(user.id, Profile.student_profile)
          @log[:success] << t(:allocation_success, scope: [:administrations, :import_users, :log], cpf: user.cpf, allocation_tag: at)
        rescue => error
          @log[:error] << t(:allocation_error, scope: [:administrations, :import_users, :log], cpf: user.cpf)
        end
      end
    end

    @log_file = save_log_into_file(@log[:success] + @log[:error])
  rescue => error
    render json: {success: false, alert: "#{error}"}, status: :unprocessable_entity
  end

  # GET /import/users/log
  def import_users_log
    authorize! :import_users, Administration

    media_path = YAML::load(File.open("config/global.yml"))[Rails.env.to_s]["import_users"]["media_path"]
    file_path = File.join(Rails.root.to_s, media_path, params[:file])

    download_file(home_path, file_path, "import-log.txt")
  end

  def responsibles
    authorize! :responsibles, Administration

    @types = CurriculumUnitType.all
  end

  def responsibles_list
    authorize! :responsibles, Administration

    allocation_tags_ids = AllocationTag.get_by_params(params, false, true)[:allocation_tags]
    @allocations        = Allocation.responsibles(allocation_tags_ids)
  end

  private

    def save_log_into_file(logs)
      filename = "#{current_user.id}-log-#{I18n.l(Time.now, format: :log)}"
      media_path = YAML::load(File.open("config/global.yml"))[Rails.env.to_s]["import_users"]["media_path"]

      FileUtils.mkdir_p(dir = File.join(Rails.root.to_s, media_path))
      File.open(File.join(dir, filename), "w") do |f|
        f.puts(logs)
      end
      filename
    end

end

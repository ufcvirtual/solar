class AdministrationsController < ApplicationController

  include FilesHelper
  include SysLog::Devise
  include SysLog::Actions

  layout false, except: [:users, :indication_users, :indication_users_specific, :indication_users_global, :allocation_approval, :lessons, :logs, :import_users, :responsibles]

  ## USERS

  def users
    authorize! :users, Administration

    @types = [ [t(".name"), 'name'], [t(".email"), 'email'], [t(".username"), 'username'], [t(".cpf"), 'cpf'] ]
  end

  def search_users
    authorize! :users, Administration

    @type_search, @text_search = params[:type_search], [URI.unescape(params[:user]).split(" ").compact.join("%"), "%"].join unless params[:user].blank?
    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on(["users"], "administrations", true, true)
    @users      = User.find_by_text_ignoring_characters(@text_search, @type_search, allocation_tags_ids).paginate(page: params[:page])
    @can_change = not(current_user.profiles_with_access_on("update_user", "administrations").empty?)

    respond_to do |format|
      format.html
      format.js
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def show_user
    authorize! :update_user, Administration
    @user, @can_change = User.find(params[:id]), true

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
    if @user.update_attributes(user_params)
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
      @user.send_reset_password_instructions
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

    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on(["allocations_user"], "administrations", false, true) # if has nil, exists an allocation with allocation_tag_id nil
    query = allocation_tags_ids.include?(nil) ? "" : ["allocation_tag_id IN (?)", allocation_tags_ids]

    @allocations_user = User.find(params[:id]).allocations.joins(:profile).where("NOT cast(profiles.types & ? as boolean)", Profile_Type_Basic).where(query)
    @profiles = @allocations_user.map(&:profile).flatten.uniq
    @periods  = [ [t(:active),''] ]
    @periods += Semester.all.map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
    @can_change = not(current_user.profiles_with_access_on("update_allocation", "administrations").empty?)
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

  ## levar metodo para allocations

  def update_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])

    @allocation.change_to_new_status params[:status].to_i, current_user

    respond_to do |format|
      format.html { render action: :show_allocation, id: params[:id] }
      format.json { render json: {status: "ok"} }
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  ## INDICATION USERS

  def indication_users
    authorize! :indication_users, Administration
  end

  def indication_users_specific
    @types = CurriculumUnitType.all
  end

  def indication_users_global
    @allocations = Allocation.joins(:profile).where(allocation_tag_id: nil).where("NOT cast(profiles.types & ? as boolean)", Profile_Type_Basic)
    @admin = true
  end

  ## ALLOCATION APPROVAL
  require 'will_paginate/array'
  def allocation_approval
    authorize! :allocation_approval, Administration
    @allocations = Allocation.pending

    if params.include?(:search)
      @text_search, @type_search = URI.unescape(params[:value]), params[:type]
      text = "%#{[@text_search.split(" ").compact.join("%"), "%"].join}" unless @text_search.blank?

      @allocations = case @type_search
      when "name"
        query = "lower(unaccent(users.name)) LIKE lower(unaccent(?))" unless @text_search.blank?
        @allocations.joins(:user).where(query, text)
      when "profile"; @allocations.joins(:profile).where("lower(unaccent(profiles.name)) LIKE lower(unaccent(?))", text)
      else
        unless text.nil?
          ats = case @type_search
            when "curriculum_unit_type"; CurriculumUnitType.where("lower(unaccent(description || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
            when "course"; Course.where("lower(unaccent(name || code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
            when "curriculum_unit"; CurriculumUnit.where("lower(unaccent(name || code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
            when "semester"; Semester.where("lower(unaccent(name || ' ')) LIKE lower(unaccent(?))", text).map(&:offers).flatten.uniq.map(&:allocation_tag).map{|a| a.related({lower: true})}
            when "group"; Group.where("lower(unaccent(code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).uniq
          else
            nil
          end
        end

        ats.nil? ? @allocations : @allocations.where(allocation_tag_id: ats.flatten.uniq)
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

    @logs, query = [], []
    date = Date.parse(params[:date]) rescue Date.today
    log  = params[:type] == 'actions' ? LogAction : LogAccess

    unless params[:user].blank?
      text_search = [URI.unescape(params[:user]).split(" ").compact.join("%"), "%"].join
      user_ids    = User.where("lower(unaccent(name || ' ' || cpf)) LIKE lower(unaccent(?))", "%#{text_search}").map(&:id).join(',')
      query << "user_id IN (#{user_ids})" unless user_ids.blank?
    end

    query << "date(created_at) = '#{date.to_s(:db)}'"
    @logs = log.where(query.join(" AND ")).order("created_at DESC").limit(100)
  end

  ## IMPORT USERS

  # GET /import/users/filter
  def import_users
    authorize! :import_users, Administration

    @types = CurriculumUnitType.all
  end

  # GET /import/users/form
  def import_users_form
    @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id].split(" ")).map(&:id)
    authorize! :import_users, Administration, on: @allocation_tags_ids, accepts_general_profile: true

  rescue CanCan::AccessDenied
    render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized
  end

  # POST /import/users/batch
  def import_users_batch
    allocation_tags_ids = params[:allocation_tags_ids].split(' ').compact.uniq.map(&:to_i)
    authorize! :import_users, Administration, on: allocation_tags_ids, accepts_general_profile: true

    raise t(:invalid_file, scope: [:administrations, :import_users]) if (file = params[:batch][:file]).nil?

    delimiter = [';', ','].include?(params[:batch][:delimiter]) ? params[:batch][:delimiter] : ';'
    result = User.import(file, delimiter)
    users = result[:imported]
    @log = result[:log]
    @count_imported = result[:log][:success].count

    users.each do |user|
      allocation_tags_ids.each do |at|
        begin
          AllocationTag.find(at).group.allocate_user(user.id, Profile.student_profile)
          @log[:success] << t(:allocation_success, scope: [:administrations, :import_users, :log], cpf: user.cpf, allocation_tag: at)
        rescue => error
          @log[:error] << t(:allocation_error, scope: [:administrations, :import_users, :log], cpf: user.cpf)
        end
      end
    end

    @log_file = save_log_into_file(@log[:success] + @log[:error])
  rescue CanCan::AccessDenied
    render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized
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
    allocation_tags_ids = AllocationTag.get_by_params(params, false, true)[:allocation_tags]
    authorize! :responsibles, Administration, {on: allocation_tags_ids, accepts_general_profile: true}

    @allocations = Allocation.responsibles(allocation_tags_ids)

  rescue CanCan::AccessDenied
    render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized
  end

  private

    def user_params
      params.require(:data).permit(:name, :email, :username, :active)
    end

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

class ProfilesController < ApplicationController

  include SysLog::Actions
  layout false, except: [:index]

  def index
    authorize! :index, Profile
    @all_profiles = Profile.all_except_basic

    render "_list", layout: false if params.include?(:list) and params[:list] == "true"
  end

  def new
    authorize! :create, Profile

    @profile = Profile.new
  end

  def edit
    authorize! :update, Profile
    @profile = Profile.find(params[:id])
  end

  def create
    authorize! :create, Profile

    @template = params[:profile].delete(:template)
    @profile  = Profile.new(params[:profile])

    if @profile.save
      @profile.resources << Profile.find(@template).resources unless @template.blank?
      params.delete(:profile)
      render json: {success: true, notice: t(:created, scope: [:profiles, :success])}
    else
      render :new
      params[:success] = false
    end
  end

  def update
    authorize! :update, Profile
    @profile = Profile.find(params[:id])

    begin
      @profile.update_attributes!(params[:profile])

      render json: {success: true, notice: t(:updated, scope: [:profiles, :success])}
    rescue
      params[:success] = false
      render :edit
    end
  end

  def destroy
    authorize! :destroy, Profile
    @profile = Profile.find(params[:id])

    begin
      @profile.destroy

      render json: {success: true, notice: t(:deleted, scope: [:profiles, :success])}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:profiles, :error])}, status: :unprocessable_entity
    end
  end

  ## GET /admin/profiles/:id/permissions
  def permissions
    authorize! :permissions, Profile
    @profile = Profile.find(params[:id]) # verificar se precisa

    @resources = Resource.joins("LEFT JOIN permissions_resources AS pr ON pr.resource_id = resources.id AND pr.profile_id = #{@profile.id}")\
      .group("resources.controller, resources.action, resources.id, resources.description, pr.profile_id")
      .select("resources.id, resources.controller, resources.action, resources.description, pr.profile_id AS permission")
      .order("resources.controller, resources.description")
  end

  ## PUT /admin/profiles/:id/permissions/grant
  def grant
    authorize! :grant, Profile
    @profile = Profile.find(params[:id])

    raise ActiveRecord::RecordNotFound unless params.include?(:resources) and not params[:resources].blank?
    profile_resources = @profile.resources.map(&:id).map(&:to_s).sort
    has_changes       = not(profile_resources == params[:resources].sort!)

    Profile.transaction do
      params[:removed], params[:added], params[:name] = (profile_resources  - params[:resources]), (params[:resources] - profile_resources), @profile.name

      if has_changes # if something has changed
        @profile.resources.delete_all
        @profile.resources << Resource.find(params[:resources]) if params.include?(:resources) and not params[:resources].blank?
      end
    end

    unless has_changes # if nothing has changed
      render json: {success: false, msg: t(:nothing_changed, scope: [:profiles, :warning]), type_msg: "warning"}
    else
      render json: {success: true, msg: t(:updated, scope: [:profiles, :success]), type_msg: "notice"}
    end
  rescue => error
    render json: {success: false, alert: t(:updated, scope: [:profiles, :error])}, status: :unprocessable_entity
  end

end

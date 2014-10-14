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
    @profile = Profile.new(profile_params)

    if @profile.save
      render json: {success: true, notice: t('profiles.success.created')}
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def update
    authorize! :update, Profile
    @profile = Profile.find(params[:id])

    if @profile.update_attributes(profile_params)
      render json: {success: true, notice: t('profiles.success.updated')}
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    authorize! :destroy, Profile
    @profile = Profile.find(params[:id])

    @profile.destroy
    render json: {success: true, notice: t('profiles.success.deleted')}
  rescue ActiveRecord::DeleteRestrictionError
    render json: {success: false, alert: t('profiles.error.deleted')}, status: :unprocessable_entity
  rescue => error
    request.format = :json
    raise error.class
  end

  ## GET /admin/profiles/:id/permissions
  def permissions
    authorize! :permissions, Profile

    @profile = Profile.find(params[:id])
    @resources = @profile.all_resources
  end

  ## PUT /admin/profiles/:id/permissions/grant
  def grant
    authorize! :grant, Profile
    @profile = Profile.find(params[:id])

    @profile.resources.delete_all
    @profile.resources << Resource.find(params[:resources]) if params[:resources].present?

    render json: {success: true, msg: t('profiles.success.updated'), type_msg: "notice"}
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def profile_params
      params.require(:profile).permit(:name, :description, :types, :status, :template)
    end

end

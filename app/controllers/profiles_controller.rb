class ProfilesController < ApplicationController

  layout false, except: [:index]

  # load_and_authorize_resource

  def index
    @all_profiles = Profile.all_except_basic

    render "_list", layout: false if params.include?(:list) and params[:list] == "true"
  end

  def new
    @profile = Profile.new
  end

  def edit
    @profile = Profile.find(params[:id])
  end

  def create
    template = params[:profile].delete(:template)
    @profile = Profile.new(params[:profile])

    if @profile.save


      ## procurar uso de permissions_resources
      ## nao eh pra deletar apenas se tiver ligacao com allocations (verificar)

      @profile.resources << Profile.find(template).resources unless template.blank?

      render json: {success: true, notice: t(:created, scope: [:profiles, :success])}

    else
      render :new
    end
  end

  def update
    @profile = Profile.find(params[:id])

    begin
      @profile.update_attributes!(params[:profile])

      render json: {success: true, notice: t(:updated, scope: [:profiles, :success])}
    rescue
      render :edit
    end
  end

  def destroy
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
    @profile = Profile.find(params[:id]) # verificar se precisa

    @resources = Resource.joins("LEFT JOIN permissions_resources AS pr ON pr.resource_id = resources.id AND pr.profile_id = #{@profile.id}")\
      .group("resources.controller, resources.action, resources.id, resources.description, pr.profile_id")
      .select("resources.id, resources.controller, resources.action, resources.description, pr.profile_id AS permission")
      .order("resources.controller, resources.description")
  end

  ## POST /admin/profiles/:id/permissions/grant
  def grant
    @profile = Profile.find(params[:id])

    begin
      Profile.transaction do
        @profile.resources.delete_all
        @profile.resources << Resource.find(params[:resources]) if params.include?(:resources) and not params[:resources].blank?
      end

      render json: {success: true, notice: t(:updated, scope: [:profiles, :success])}
    rescue
      render json: {success: false, alert: t(:updated, scope: [:profiles, :error])}, status: :unprocessable_entity
    end
  end

end

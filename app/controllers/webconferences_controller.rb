class WebconferencesController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  before_filter :prepare_for_group_selection, only: :index

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter only: [:edit, :update] do |controller| # futuramente show aqui também
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@webconference = Webconference.find(params[:id]))
  end

  def index
    authorize! :index, Webconference, on: [at = active_tab[:url][:allocation_tag_id]]

    @webconferences = Webconference.all_by_allocation_tags(AllocationTag.find(at).related(upper: true))
  end

  # GET /webconferences/list
  # GET /webconferences/list.json
  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Webconference, on: @allocation_tags_ids

    @webconferences = Webconference.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).uniq
  end

  # GET /webconferences/new
  # GET /webconferences/new.json
  def new
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @webconference = Webconference.new
  end

  # GET /webconferences/1/edit
  def edit
    authorize! :update, Webconference, on: @allocation_tags_ids

    @webconference = Webconference.find(params[:id])
  end

  # POST /webconferences
  # POST /webconferences.json
  def create
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @webconference = Webconference.new(params[:webconference])
    @webconference.moderator = current_user

    begin
      Webconference.transaction do
        @webconference.save!
        @webconference.academic_allocations.create! @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:webconferences, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
      params[:success] = false
      render :new
    end
  end

  # PUT /webconferences/1
  # PUT /webconferences/1.json
  def update
    authorize! :update, Webconference, on: @webconference.academic_allocations.pluck(:allocation_tag_id)

    @webconference.update_attributes!(params[:webconference])

    render json: {success: true, notice: t(:updated, scope: [:webconferences, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    params[:success] = false
    render :edit
  end

  # DELETE /webconferences/1
  # DELETE /webconferences/1.json
  def destroy
    @webconferences = Webconference.where(id: params[:id].split(",").flatten)
    authorize! :destroy, Webconference, on: @webconferences.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @webconferences.destroy_all
    render json: {success: true, notice: t(:deleted, scope: [:webconferences, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t(:deleted, scope: [:webconferences, :error])}, status: :unprocessable_entity
  end
end

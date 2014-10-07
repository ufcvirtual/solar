class BibliographiesController < ApplicationController

  include SysLog::Actions

  layout false, except: :index # define todos os layouts do controller como falso
  before_filter :prepare_for_group_selection, only: [:index]

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter only: [:edit, :update] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@bibliography = Bibliography.find(params[:id]))
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Bibliography, on: @allocation_tags_ids

    @bibliographies = Bibliography.all_by_allocation_tags(@allocation_tags_ids.split(" ").flatten)
  end

  # GET /bibliographies
  def index
    authorize! :index, Bibliography, on: [at = active_tab[:url][:allocation_tag_id]]

    @bibliographies = Bibliography.all_by_allocation_tags(AllocationTag.find(at).related(upper: true)) # tem que listar bibliografias relacionadas para cima
  end

  # GET /bibliographies/new
  def new
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @bibliography = Bibliography.new type_bibliography: params[:type_bibliography]
    @bibliography.authors.build
  end

  # GET /bibliographies/1/edit
  def edit
    authorize! :update, Bibliography, on: @allocation_tags_ids
  end

  # POST /bibliographies
  def create
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @bibliography = Bibliography.new(params[:bibliography])

    begin
      Bibliography.transaction do
        @bibliography.save!
        @bibliography.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
    render json: {success: true, notice: t(:created, scope: [:bibliographies, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
      params[:success] = false
      render :new
    end
  end

  # PUT /bibliographies/1
  def update
    authorize! :update, Bibliography, on: @bibliography.academic_allocations.pluck(:allocation_tag_id)
    @bibliography.update_attributes!(params[:bibliography])
    render json: {success: true, notice: t(:updated, scope: [:bibliographies, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    params[:success] = false
    render :edit
  end

  # DELETE /bibliographies/1
  def destroy
    @bibliographies = Bibliography.where(id: params[:id].split(","))
    authorize! :destroy, Bibliography, on: @bibliographies.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @bibliographies.destroy_all

    render json: {success: true, notice: t(:deleted, scope: [:bibliographies, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t(:deleted, scope: [:bibliographies, :error])}, status: :unprocessable_entity
  end
end

class BibliographiesController < ApplicationController

  layout false, except: :index # define todos os layouts do controller como falso


  def list
    authorize! :list, Bibliography, on: @allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(",") : params[:allocation_tags_ids])

    @bibliographies = Bibliography.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq
  end

  # GET /bibliographies
  # GET /bibliographies.json
  def index
    authorize! :index, Bibliography

    @bibliographies = Bibliography.all_by_allocation_tags(AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])) # sempre dentro de uma UC

    respond_to do |format|
      format.html
      format.json { render json: @bibliographies }
    end
  end

  # GET /bibliographies/new
  # GET /bibliographies/new.json
  def new
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @bibliography = Bibliography.new type_bibliography: params[:type_bibliography]
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
  end

  # GET /bibliographies/1/edit
  def edit
    authorize! :update, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @bibliography = Bibliography.find(params[:id])
    @groups_codes = @bibliography.groups.map(&:code)
  end

  # POST /bibliographies
  # POST /bibliographies.json
  def create
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
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
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      render :new
    end
  end

  # PUT /bibliographies/1
  # PUT /bibliographies/1.json
  def update
    authorize! :update, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @bibliography = Bibliography.find(params[:id])
    begin
      @bibliography.update_attributes(params[:bibliography])

      render json: {success: true, notice: t(:updated, scope: [:bibliographies, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @bibliography.groups.map(&:code)
      render :edit
    end
  end

  # DELETE /bibliographies/1
  # DELETE /bibliographies/1.json
  def destroy
    authorize! :destroy, Bibliography, on: params[:allocation_tags_ids]

    begin
      @bibliography = Bibliography.where(id: params[:id].split(","))
      @bibliography.destroy_all

      render json: {success: true, notice: t(:deleted, scope: [:bibliographies, :success])}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:bibliographies, :error])}, status: :unprocessable_entity
    end
  end
end

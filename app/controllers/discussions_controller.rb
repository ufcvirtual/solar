class DiscussionsController < ApplicationController

  layout false, except: :index # define todos os layouts do controller como falso

  authorize_resource only: :index

  before_filter :prepare_for_group_selection, only: :index

  def index
    begin
      allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions      = Discussion.all_by_allocation_tags(AllocationTag.find_related_ids(allocation_tag_id))
    rescue
      @discussions      = []
    end

    respond_to do |format|
      format.html
      format.xml  { render xml: @discussions }
      format.json  { render json: {discussions: @discussions } } # SolarMobilis: GET /groups/:group_id/discussions/mobilis_list.json
    end
  end

  def new
    authorize! :new, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @discussion = Discussion.new
    @discussion.build_schedule(start_date: Date.current, end_date: Date.current)
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
  end

  def create
    authorize! :create, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @discussion = Discussion.new params[:discussion]

    begin
      Discussion.transaction do
        @discussion.allocation_tags_ids = @allocation_tags_ids
        @discussion.save!
        @discussion.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:discussions, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue 
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      render :new
    end
  end

  def list
    @allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(",") : params[:allocation_tags_ids])

    authorize! :list, Discussion, on: @allocation_tags_ids
    @discussions = Discussion.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq
  end

  def edit
    authorize! :edit, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @discussion = Discussion.find(params[:id])
    @groups_codes = @discussion.groups.map(&:code)
  end

  def update
    authorize! :update, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @discussion = Discussion.find(params[:id])
    begin
      @discussion.allocation_tags_ids = @allocation_tags_ids
      @discussion.update_attributes!(params[:discussion])
      render json: {success: true, notice: t(:updated, scope: [:discussions, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue 
      @groups_codes = @discussion.groups.map(&:code)
      render :edit
    end
  end

  def destroy
    authorize! :destroy, Discussion, on: params[:allocation_tags_ids]

    begin
      @discussions = Discussion.where(id: params[:id].split(","))
      raise has_posts = true if @discussions.map(&:can_destroy?).include?(false)

      Discussion.transaction do
        @discussions.destroy_all
      end

      render json: {success: true, notice: t(:deleted, scope: [:discussions, :success])}
    rescue
      render json: {success: false, alert: (has_posts ? t(:discussion_with_posts, scope: [:discussions, :error]) : t(:deleted, scope: [:discussions, :error]))}, status: :unprocessable_entity
    end
  end

end

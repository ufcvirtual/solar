class DiscussionsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index # define todos os layouts do controller como falso

  authorize_resource only: :index

  before_filter :prepare_for_group_selection, only: :index

  def index
    begin
      @allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions = Discussion.all_by_allocation_tags(@allocation_tag_id)
    rescue
      @discussions = []
    end
    authorize! :show, Discussion, on: [@allocation_tag_id]

    respond_to do |format|
      format.html
      format.xml  { render xml: @discussions }
      format.json  { render json: (params[:mobilis] ? {discussions: @discussions.map(&:resume) } : @discussions.map(&:resume))} # SolarMobilis: GET /groups/:group_id/discussions/mobilis_list.json
    end
  end

  def new
    authorize! :new, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @discussion = Discussion.new
    @discussion.build_schedule(start_date: Date.current, end_date: Date.current)
    @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten})
  end

  def create
    authorize! :create, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
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
      @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten})
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
      render :new
    end
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Discussion, on: @allocation_tags_ids

    @discussions = Discussion.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).uniq.select("discussions.*, schedules.start_date AS start_date").order("start_date")
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edit
    authorize! :edit, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @discussion = Discussion.find(params[:id])
    @groups = @discussion.groups
  end

  def update
    @allocation_tags_ids, @discussion = params[:allocation_tags_ids], Discussion.find(params[:id])
    authorize! :update, Discussion, on: @discussion.academic_allocations.pluck(:allocation_tag_id)

    @discussion.update_attributes!(params[:discussion])

    render json: {success: true, notice: t(:updated, scope: [:discussions, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    @groups = @discussion.groups
    render :edit
  end

  def destroy
    @discussions = Discussion.where(id: params[:id].split(","))
    authorize! :destroy, Discussion, on: @discussions.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    raise has_posts = true if @discussions.map(&:can_destroy?).include?(false)

    Discussion.transaction do
      @discussions.destroy_all
    end

    render json: {success: true, notice: t(:deleted, scope: [:discussions, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: (has_posts ? t(:discussion_with_posts, scope: [:discussions, :error]) : t(:deleted, scope: [:discussions, :error]))}, status: :unprocessable_entity
  end

  def show
    authorize! :show, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @discussion   = Discussion.find(params[:id])
    @groups = @discussion.groups
  end

end

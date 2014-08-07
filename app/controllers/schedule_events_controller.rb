class ScheduleEventsController < ApplicationController

  layout false
  
  def new
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @schedule_event = ScheduleEvent.new
    @schedule_event.build_schedule(start_date: Date.current, end_date: Date.current)
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).map(&:code).uniq
  end

  def create
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @schedule_event = ScheduleEvent.new params[:schedule_event]

    begin
      ScheduleEvent.transaction do
        @schedule_event.save!
        @schedule_event.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:schedule_events, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue 
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:code).uniq
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
      render :new
    end
  end

  def edit
    authorize! :edit, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @schedule_event = ScheduleEvent.find(params[:id])
    @schedule       = @schedule_event.schedule
    @groups_codes   = @schedule_event.groups.map(&:code)
  end

  def update
    @allocation_tags_ids, @schedule_event = params[:allocation_tags_ids], ScheduleEvent.find(params[:id])
    authorize! :edit, ScheduleEvent, on: @schedule_event.academic_allocations.pluck(:allocation_tag_id)
    
    @schedule_event.update_attributes!(params[:schedule_event]) if @schedule_event.can_change?

    render json: {success: true, notice: t(:updated, scope: [:schedule_events, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    @groups_codes = @schedule_event.groups.map(&:code)
    render :edit
  end

  def destroy
    schedule_event = ScheduleEvent.find(params[:id])
    authorize! :destroy, ScheduleEvent, on: schedule_event.academic_allocations.pluck(:allocation_tag_id)

    schedule_event.try(:destroy) if schedule_event.can_change?

    render json: {success: true, notice: t(:deleted, scope: [:schedule_events, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t(:deleted, scope: [:schedule_events, :error])}, status: :unprocessable_entity
  end

  def show
    authorize! :show, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @schedule_event = ScheduleEvent.find(params[:id])
    @groups_codes   = @schedule_event.groups.map(&:code)
  end

end

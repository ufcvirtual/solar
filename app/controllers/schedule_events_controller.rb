class ScheduleEventsController < ApplicationController

  layout false
  
  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    # authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @schedule_event = ScheduleEvent.new
    @schedule_event.build_schedule(start_date: Date.current, end_date: Date.current)
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    # authorize! :create, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
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
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      render :new
    end
  end

  def edit
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # authorize! :update, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @schedule_event = ScheduleEvent.find(params[:id])
    @schedule = @schedule_event.schedule
    @groups_codes = @schedule_event.groups.map(&:code)
  end

  def update
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # authorize! :update, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @schedule_event = ScheduleEvent.find(params[:id])
    
    begin
      @schedule_event.update_attributes!(params[:schedule_event])

      render json: {success: true, notice: t(:updated, scope: [:schedule_events, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @schedule_event.groups.map(&:code)
      render :edit
    end
  end

  def destroy
    # authorize! :destroy, ScheduleEvent, on: params[:allocation_tags_ids]
    begin
      ScheduleEvent.find(params[:id]).try(:destroy)
      render json: {success: true, notice: t(:deleted, scope: [:schedule_events, :success])}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:schedule_events, :error])}, status: :unprocessable_entity
    end
  end

  def dropdown_content
    model_name = params[:type].constantize
    render partial: "event_content", locals: {event: model_name.find(params[:id]), model_name: model_name, allocation_tags_ids: params[:allocation_tags_ids].split(" ")}
  end

  def show
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # authorize! :show, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @schedule_event = ScheduleEvent.find(params[:id])
    @groups_codes = @schedule_event.groups.map(&:code)
  end

end

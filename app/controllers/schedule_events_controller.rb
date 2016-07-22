class ScheduleEventsController < ApplicationController

  include SysLog::Actions

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  before_filter only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@schedule_event = ScheduleEvent.find(params[:id]))
  end

  layout false

  def show
    authorize! :show, ScheduleEvent, on: @allocation_tags_ids
  end

  def new
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @schedule_event = ScheduleEvent.new
    @schedule_event.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  def create
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @schedule_event = ScheduleEvent.new schedule_event_params
    @schedule_event.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten

    if @schedule_event.save
      render_schedule_event_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def edit
    authorize! :edit, ScheduleEvent, on: @allocation_tags_ids
  end

  def update
    authorize! :edit, ScheduleEvent, on: @schedule_event.academic_allocations.pluck(:allocation_tag_id)

    if @schedule_event.can_change? and @schedule_event.update_attributes(schedule_event_params)
      render_schedule_event_success_json('updated')
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @schedule_event = ScheduleEvent.find(params[:id])
    authorize! :destroy, ScheduleEvent, on: @schedule_event.academic_allocations.pluck(:allocation_tag_id)

    evaluative = @schedule_event.verify_evaluatives
    if @schedule_event.can_remove_groups? 
      @schedule_event.destroy
      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:schedule_events, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    else
      render json: {success: false, alert: t('schedule_events.error.evaluated')}, status: :unprocessable_entity
    end
  rescue => error
    render_json_error(error, 'schedule_events.error')
  end

  def evaluate_user
    authorize! :evaluate, ScheduleEvent, {on: allocation_tag = active_tab[:url][:allocation_tag_id]}
    @schedule_event = ScheduleEvent.find(params[:id])
    @ac = @schedule_event.academic_allocations.where(allocation_tag_id: allocation_tag).first
    @user = User.find(params[:user_id])
    raise 'not_student' unless @user.has_profile_type_at(allocation_tag)
    @acu = AcademicAllocationUser.find_one(@ac.id, params[:user_id])

  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    error_message = (I18n.translate!("schedule_events.error.#{error}", raise: true) rescue t("schedule_events.error.general_message"))
    render text: error_message
  end

  private

    def schedule_event_params
      params.require(:schedule_event).permit(:title, :description, :type_event, :start_hour, :end_hour, :place, :integrated, schedule_attributes: [:id, :start_date, :end_date])
    end

    def render_schedule_event_success_json(method)
      render json: {success: true, notice: t(method, scope: 'schedule_events.success')}
    end

end

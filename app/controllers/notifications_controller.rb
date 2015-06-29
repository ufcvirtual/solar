class NotificationsController < ApplicationController

  include SysLog::Actions

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  before_filter only: [:edit, :update] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@notification = Notification.find(params[:id]))
  end

  layout false

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Notification, on: @allocation_tags_ids

    @notifications = Notification.joins(:allocation_tags).where(allocation_tags: { id: @allocation_tags_ids.split(" ").flatten }).uniq
  end

  # GET /notifications
  def index
    @notifications = Notification.of_user(current_user)
  end

  # GET /notifications/1
  def show
    @notification = Notification.find(params[:id])
    @notification.mark_as_read(current_user)
  end

  # GET /notifications/new
  def new
    authorize! :create, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @notification = Notification.new
    @notification.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  # GET /notifications/1/edit
  def edit
    authorize! :update, Notification, on: @allocation_tags_ids
  end

  # POST /notifications
  def create
    authorize! :create, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @notification = Notification.new notification_params
    @notification.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten

    if @notification.save
      render_notification_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # PUT /notifications/1
  def update
    authorize! :update, Notification, on: @notification.academic_allocations.pluck(:allocation_tag_id)

    if @notification.update_attributes(notification_params)
      render_notification_success_json('updated')
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # DELETE /notifications/1
  def destroy
    @notifications = Notification.where(id: params[:id].split(","))

    authorize! :destroy, Notification, on: @notifications.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @notifications.destroy_all
    render_notification_success_json('deleted')
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def notification_params
      params.require(:notification).permit(:title, :description, schedule_attributes: [:id, :start_date, :end_date])
    end

    def render_notification_success_json(method)
      render json: {success: true, notice: t(method, scope: 'notifications.success')}
    end

end

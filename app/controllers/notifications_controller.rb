class NotificationsController < ApplicationController

  include SysLog::Actions

  layout false

  def list
    authorize! :list, Notification, on: @allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(",") : params[:allocation_tags_ids])

    @notifications = Notification.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq
  end

  # GET /notifications
  # GET /notifications.json
  def index
    @notifications = Notification.of_user(current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notifications }
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
    @notification = Notification.find(params[:id])
    @notification.mark_as_read(current_user)

    # @to = (@notification.allocation_tags & current_user.all_allocation_tags(objects: true)).map(&:info)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notification }
    end
  end

  # GET /notifications/new
  # GET /notifications/new.json
  def new
    authorize! :create, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @notification = Notification.new
    @notification.build_schedule(start_date: Date.today, end_date: Date.today)

    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
  end

  # GET /notifications/1/edit
  def edit
    authorize! :update, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @notification = Notification.find(params[:id])
    @groups_codes = @notification.groups.map(&:code)
  end

  # POST /notifications
  # POST /notifications.json
  def create
    authorize! :create, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @notification = Notification.new(params[:notification])

    begin
      Notification.transaction do
        @notification.save!
        @notification.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:notifications, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      params[:success] = false
      render :new
    end
  end

  # PUT /notifications/1
  # PUT /notifications/1.json
  def update
    authorize! :update, Notification, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @notification = Notification.find(params[:id])
    begin
      @notification.update_attributes!(params[:notification])

      render json: {success: true, notice: t(:updated, scope: [:notifications, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @notification.groups.map(&:code)
      params[:success] = false
      render :edit
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    authorize! :destroy, Notification, on: params[:allocation_tags_ids]

    @notification = Notification.where(id: params[:id].split(","))
    unless @notification.empty?
      @notification.destroy_all
      render json: {success: true, notice: t(:deleted, scope: [:notifications, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:notifications, :error])}, status: :unprocessable_entity
    end
  end
end

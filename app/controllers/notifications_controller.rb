class NotificationsController < ApplicationController

  include SysLog::Actions

  before_filter only: [:edit, :new, :create] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
  end

  before_filter only: [:edit, :update] do |controller|
    get_groups_by_tool(@notification = Notification.find(params[:id]))
    authorize! :update, Notification, {on: @notification.academic_allocations.pluck(:allocation_tag_id), accepts_general_profile: true} 
  end

  before_filter only: [:new, :create] do |controller|
    get_groups_by_allocation_tags
    authorize! :create, Notification, {on: @allocation_tags_ids, accepts_general_profile: true} 
  end


  before_filter only: [:new, :edit, :create, :update] do |controller|
    @can_mark_as_mandatory = current_user.profiles_with_access_on(:mark_as_mandatory, :notifications, (@allocation_tags_ids.split(' ') rescue nil), false, false, true).any?
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

  def mandatory
    @notifications = Notification.mandatory_of_user(current_user)

    render json: {count: @notifications.count}
  end

  # GET /notifications/1
  def show
    @all_notification = Notification.of_user(current_user)
    @notification = Notification.find(params[:id])
    notification_show(@notification)
  end

  require 'will_paginate/array'
  def show_mandatory
    @notification = Notification.mandatory_of_user(current_user).paginate(per_page: 1, page: params[:page] || 1)
    notification_show(@notification.first)
  end

  # GET /notifications/new
  def new
    @notification = Notification.new
    @notification.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  # GET /notifications/1/edit
  def edit
  end

  # POST /notifications
  def create
    @notification = Notification.new notification_params
    @notification.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten 

    raise CanCan::AccessDenied if @notification.mandatory_reading && !@can_mark_as_mandatory

    if @notification.save
      all_groups = Offer.find(params[:offer_id]).try(:groups) if params.include?(:offer_id)
      render partial: "notification", locals: {notification: @notification, all_groups: all_groups, destroy: true}
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # PUT /notifications/1
  def update
    raise CanCan::AccessDenied if notification_params[:mandatory_reading] && !@can_mark_as_mandatory

    if @notification.update_attributes(notification_params)
      all_groups = Offer.find(params[:offer_id]).try(:groups) if params.include?(:offer_id)
      render partial: "notification", locals: {notification: @notification, all_groups: all_groups, destroy: true}
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

    authorize! :destroy, Notification, {on: @notifications.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten, accepts_general_profile: true} if params[:allocation_tags_ids].blank?
    
    @notifications.destroy_all
    render_notification_success_json('deleted')
  rescue => error
    request.format = :json
    raise error.class
  end

  def read_later
    Notification.find(params[:id]).mark_as_unread(current_user.id)
    render json: {success: true}, status: :ok
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  private

    def notification_params
      params.require(:notification).permit(:title, :description, :mandatory_reading, schedule_attributes: [:id, :start_date, :end_date])
    end

    def render_notification_success_json(method)
      render json: {success: true, notice: t(method, scope: 'notifications.success')}
    end

    def notification_show(notification)
      notification.mark_as_read(current_user)
    
      unless notification.allocation_tags.blank?
        allocation_tags = notification.allocation_tags
        @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags.pluck(:id)}).pluck(:code) if allocation_tags.size > 1
        @allocation_tag = allocation_tags.first
      end  
    end

end

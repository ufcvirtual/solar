class AssignmentWebconferencesController < ApplicationController

  include SysLog::Actions
  include AssignmentsHelper
  include Bbb
  include IpRealHelper

  before_filter :set_current_user, except: [:edit, :show]
  before_filter :get_ac, only: :new

  before_filter only: [:edit, :update, :destroy, :remove_record, :show, :change_status, :access] do |controller|
    @assignment_webconference = AssignmentWebconference.find(params[:id])
  end

  layout false

  def new
    group = GroupAssignment.by_user_id(current_user.id, @ac.id)
    academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, active_tab[:url][:allocation_tag_id], current_user.id, group.try(:id), true, nil)
    @assignment_webconference = AssignmentWebconference.new academic_allocation_user_id: academic_allocation_user.id
    verify_ip!(@assignment_webconference.assignment.id, :assignment, @assignment_webconference.assignment.controlled, :text)
  end

  def create
    verify_owner!(assignment_webconference_params)
    @assignment_webconference = AssignmentWebconference.new assignment_webconference_params
    set_ip_user
    @assignment_webconference.save!

    render partial: 'webconference', locals: { webconference: @assignment_webconference, view_disabled: false }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue => error
    if @assignment_webconference.errors.any?
      render :new
    else
      render_json_error(error, 'assignment_webconferences.error')
    end
  end

  def edit
    verify_ip!(@assignment_webconference.assignment.id, :assignment, @assignment_webconference.assignment.controlled, :text)
  end

  def update
    owner(assignment_webconference_params)
    set_ip_user
    @assignment_webconference.update_attributes! assignment_webconference_params

    render partial: 'webconference', locals: { webconference: @assignment_webconference, view_disabled: false }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue ActiveRecord::AssociationTypeMismatch
      render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue => error
    if @assignment_webconference.errors.any?
      render :edit
    else
      render_json_error(error, 'assignment_webconferences.error')
    end
  end

  def destroy
    verify_owner!(@assignment_webconference)
    set_ip_user
    @assignment_webconference.destroy
    render json: { success: true, notice: t('assignment_webconferences.success.removed') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render_json_error(error, 'assignment_webconferences.error')
  end

  def remove_record
    verify_owner!(@assignment_webconference)

    verify_ip!(@assignment_webconference.assignment.id, :assignment, @assignment_webconference.assignment.controlled, :raise)
    @assignment_webconference.can_remove_records?


    if params.include?(:recordID)
      @assignment_webconference.remove_record(params[:recordID])
      save_log(@assignment_webconference)
    else
      @assignment_webconference.remove_records
      save_log(@assignment_webconference)
    end

    render json: { success: true, notice: t('assignment_webconferences.success.record') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render_json_error(error, 'assignment_webconferences.error')
  end

  def show
    verify_owner!(@assignment_webconference)
    render partial: 'webconference', locals: { webconference: @assignment_webconference, view_disabled: false }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def get_record
    @assignment_webconference = AssignmentWebconference.find(params[:id])
    api = @assignment_webconference.bbb_prepare
    academic_allocation_user = AcademicAllocationUser.find(params[:academic_allocation_user_id])
    at_id                    = active_tab[:url][:allocation_tag_id]
    verify_owner_or_responsible!(at_id, academic_allocation_user)

    raise CanCan::AccessDenied if current_user.is_researcher?(AllocationTag.find(at_id).related)

    raise 'offline'          unless bbb_online?(api)
    raise 'still_processing' unless @assignment_webconference.is_over?

    begin
      raise CanCan::AccessDenied unless @own_assignment
      @can_remove_record = true
    rescue
      @can_remove_record = false
    end

    @recordings = @assignment_webconference.recordings([], (at_id.class == Array ? nil : at_id))
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue URI::InvalidURIError
    render_json_error('removed_record', 'webconferences.list')
  rescue => error
    render_json_error(error, 'webconferences.error')
  end

  def change_status
    verify_owner!(@assignment_webconference)
    raise 'date_range' unless @assignment_webconference.in_time?
    raise 'on_going' if @assignment_webconference.on_going?
    set_ip_user
    @assignment_webconference.update_attributes final: !@assignment_webconference.final

    respond_to do |format|
      format.json { render json: {success: true} }
      format.js
    end
  rescue => error
    error_message = error == CanCan::AccessDenied ? t(:no_permission) : (I18n.translate!("webconferences.error.#{error}", raise: true) rescue t("webconferences.error.general_message"))
    Rails.logger.info "[ERROR] [APP] [#{Time.now}] [#{error}] [#{(message.nil? ? error_message : error.message)}]"
    respond_to do |format|
      format.json { render json: { success: false, msg: error_message }, status: :unprocessable_entity }
      format.js { render js: "flash_message('#{error_message}', 'alert');" }
    end
  end

  def access
    verify_owner_or_responsible!(active_tab[:url][:allocation_tag_id], @assignment_webconference.academic_allocation_user, :raise)
    raise 'on_going' unless @assignment_webconference.on_going?

    url = @assignment_webconference.get_bbb_url(current_user)
    URI.parse(url).path
    
    render json: { success: true, url: url }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  private

    def save_log(assignment_webconference)
      log = if params.include?(:recordID)
        { description: "assignment_webconference: #{assignment_webconference.id}  removing recording #{params[:recordID]} by user #{current_user.id}" }
      else
        { description: "assignment_webconference: #{assignment_webconference.id}  removing all recordings by user #{current_user.id}" }
      end

      LogAction.create({ log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, ip: get_remote_ip, allocation_tag_id: assignment_webconference.allocation_tag.id, academic_allocation_id: assignment_webconference.academic_allocation.id }.merge!(log))
    end

    def assignment_webconference_params
      params.require(:assignment_webconference).permit(:academic_allocation_user_id, :title, :initial_time, :duration, :is_recorded, :server)
    end

end

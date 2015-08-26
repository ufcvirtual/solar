require 'will_paginate/array'

class WebconferencesController < ApplicationController

  include SysLog::Actions
  include Bbb

  layout false, except: [:index, :preview]

  before_filter :prepare_for_group_selection, only: :index

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter only: [:edit, :update] do |controller| # futuramente show aqui também
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@webconference = Webconference.find(params[:id]))
  end

  def index
    authorize! :index, Webconference, on: [at = active_tab[:url][:allocation_tag_id]]

    @webconferences = Webconference.all_by_allocation_tags(AllocationTag.find(at).related(upper: true))
    @online         = bbb_online?
    @recordings     = bbb_all_recordings if @online
    @can_see_access = can? :list_access, Webconference, { on: at }
    @meetings       = get_meetings
  end

  # GET /webconferences/list
  # GET /webconferences/list.json
  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Webconference, on: @allocation_tags_ids

    @webconferences = Webconference.joins(academic_allocations: :allocation_tag).where(allocation_tags: { id: @allocation_tags_ids.split(' ').flatten }).uniq
  end

  # GET /webconferences/new
  # GET /webconferences/new.json
  def new
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @webconference = Webconference.new
  end

  # GET /webconferences/1/edit
  def edit
    authorize! :update, Webconference, on: @allocation_tags_ids

    @webconference = Webconference.find(params[:id])
  end

  # POST /webconferences
  # POST /webconferences.json
  def create
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten

    @webconference = Webconference.new(webconference_params)
    @webconference.moderator = current_user

    begin
      Webconference.transaction do
        @webconference.save!
        @webconference.academic_allocations.create! @allocation_tags_ids.map { |at| { allocation_tag_id: at } }
        @webconference.verify_quantity(@allocation_tags_ids)
      end
      render json: { success: true, notice: t(:created, scope: [:webconferences, :success]) }
    rescue ActiveRecord::AssociationTypeMismatch
      render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
    rescue => error
      @allocation_tags_ids = @allocation_tags_ids.join(' ')
      params[:success] = false
      render :new
    end
  end

  # PUT /webconferences/1
  # PUT /webconferences/1.json
  def update
    authorize! :update, Webconference, on: @webconference.academic_allocations.pluck(:allocation_tag_id)

    @webconference.update_attributes!(webconference_params)

    render json: { success: true, notice: t(:updated, scope: [:webconferences, :success]) }
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue
    params[:success] = false
    render :edit
  end

  # DELETE /webconferences/1
  # DELETE /webconferences/1.json
  def destroy
    @webconferences = Webconference.where(id: params[:id].split(',').flatten)
    authorize! :destroy, Webconference, on: @webconferences.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @webconferences.destroy_all
    
    render json: { success: true, notice: t(:deleted, scope: [:webconferences, :success]) }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'webconferences.error', 'deleted')
  end

  # GET /webconferences/preview
  def preview
    ats = current_user.allocation_tags_ids_with_access_on('preview', 'webconferences', false, true)
    @webconferences = Webconference.all_by_allocation_tags(ats, { asc: false }).paginate(page: params[:page])
    @online         = bbb_online?
    @recordings     = bbb_all_recordings if @online
    @can_see_access = can? :list_access, Webconference, { on: ats, accepts_general_profile: true }
    @meetings       = get_meetings
  end

  # PUT /webconferences/remove_record/1
  def remove_record
    academic_allocations = AcademicAllocation.where(id: params[:id].split(',').flatten)
    webconferences      = Webconference.where(id: academic_allocations.map(&:academic_tool_id))

    authorize! :preview, Webconference, { on: academic_allocations.map(&:allocation_tag_id).flatten, accepts_general_profile: true }

    webconferences.map(&:can_remove_records?)
    Webconference.remove_record(academic_allocations)

    render json: { success: true, notice: t(:record_deleted, scope: [:webconferences, :success]) }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'webconferences.error', 'record_not_deleted')
  end

  def access
    authorize! :interact, Webconference, { on: [at_id = active_tab[:url][:allocation_tag_id] || params[:at_id]] }
    
    webconference = Webconference.find(params[:id])
    url   = webconference.link_to_join(current_user, at_id, true)
    URI.parse(url).path

    LogAction.access_webconference(academic_allocation_id: webconference.academic_allocations.where(allocation_tag_id: at_id).first.id, user_id: current_user.id, ip: request.remote_ip, allocation_tag_id: at_id) if AllocationTag.find(at_id).is_student_or_responsible?(current_user.id)

    render json: { success: true, url: url }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  def list_access
    @webconference = Webconference.find(params[:id])
    authorize! :list_access, Webconference, { on: at_id = active_tab[:url][:allocation_tag_id] || params[:at_id] || @webconference.allocation_tags.map(&:id), accepts_general_profile: true }

    academic_allocations_ids = (@webconference.shared_between_groups ? @webconference.academic_allocations.map(&:id) : @webconference.academic_allocations.where(allocation_tag_id: at_id).first.try(:id))

    @logs = @webconference.get_access(academic_allocations_ids)
    @researcher = current_user.is_researcher?(AllocationTag.where(id: at_id).map(&:related))
    @too_old    = @webconference.initial_time.to_date < Date.parse(YAML::load(File.open('config/webconference.yml'))['participant_log_date'])

    render partial: 'list_access'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  private

  def webconference_params
    params.require(:webconference).permit(:description, :duration, :initial_time, :title, :is_recorded, :shared_between_groups)
  end

end

require 'will_paginate/array'
require "em-websocket"

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

  before_filter :close_expired_support_help, only: :preview

  def index
    authorize! :index, Webconference, on: [at = active_tab[:url][:allocation_tag_id]]
    @can_see_access = can? :list_access, Webconference, { on: at }
    @user = current_user
    @is_student = @user.is_student?([at])
    @webconferences = Webconference.all_by_allocation_tags(AllocationTag.find(at).related(upper: true), {asc: false}, (@can_see_access ? nil : current_user.id))
    @webconferences_online = @webconferences.select { |w| w.on_going? } # Webs online para a escolha pelo usuário no atendimento em tempo real
    @request_support = params[:request_support] # Para abrir o fancybox do atendimento
  end

  # GET /webconferences/list
  # GET /webconferences/list.json
  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    @selected = params[:selected]
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
      @webconference.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten
      @webconference.save!
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

    evaluative = @webconferences.map(&:verify_evaluatives).include?(true)
    Webconference.transaction do
      @webconferences.destroy_all
    end
    
    message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:webconferences, :success])]
    render json: { success: true, type_message: message.first,  message: message.last }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'webconferences.error', 'deleted')
  end

  # GET /webconferences/preview
  def preview
    ats = current_user.allocation_tags_ids_with_access_on('preview', 'webconferences', false, true)
    @filter_situation = params[:status] || 'in_progress'
    @webconferences = Webconference.all_by_allocation_tags(ats, { asc: false }).paginate(:per_page => 100, page: params[:page])
    if @filter_situation == 'recorded'
      @webconferences = (@webconferences.select { |web|  web.is_recorded }).paginate(:per_page => 100, page: params[:page])
    elsif @filter_situation != 'all'
      @webconferences = (@webconferences.select { |web|  web.situation ==  @filter_situation }).paginate(:per_page => 100, page: params[:page])
    end
    @can_see_access = can? :list_access, Webconference, { on: ats, accepts_general_profile: true }
    @can_remove_record = (can? :manage_record, Webconference, { on: ats, accepts_general_profile: true })
  end

  # DELETE /webconferences/remove_record/1
  def remove_record
    if params.include?(:webconference)
      webconferences = [Webconference.find(params[:webconference])]
      begin
        authorize! :manage_record, Webconference, { on: webconferences.flatten.first.academic_allocations.map(&:allocation_tag_id).flatten, accepts_general_profile: true }
      rescue
        raise CanCan::AccessDenied unless current_user.id == webconferences.first.user_id
      end
    else
      academic_allocations = AcademicAllocation.where(id: params[:id].split(',').flatten)
      webconferences      = Webconference.where(id: academic_allocations.map(&:academic_tool_id))
      authorize! :manage_record, Webconference, { on: academic_allocations.map(&:allocation_tag_id).flatten, accepts_general_profile: true }
    end

    webconferences.map(&:can_remove_records?)

    copies = webconferences.map(&:origin_meeting_id).reject{ |w| w.to_s.blank? }
    raise 'copy' if copies.any?

    if params.include?(:recordID)
      webconferences.first.remove_record(params[:recordID], params[:at])
      save_log(webconferences.first)
    else
      Webconference.remove_record(academic_allocations)
      save_log(webconferences.first, academic_allocations)
    end

    render json: { success: true, notice: t(:record_deleted, scope: [:webconferences, :success]) }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'webconferences.error', 'record_not_deleted')
  end

  def access
    if Exam.verify_blocking_content(current_user.id)
      render text: t('exams.restrict')
    else
      authorize! :interact, Webconference, { on: [at_id = active_tab[:url][:allocation_tag_id] || params[:at_id]] }
      
      webconference = Webconference.find(params[:id])
      url   = webconference.link_to_join(current_user, at_id, true)
      URI.parse(url).path

      ac_id = (webconference.academic_allocations.size == 1 ? webconference.academic_allocations.first.id : webconference.academic_allocations.where(allocation_tag_id: at_id).first.id)
     
      acu = AcademicAllocationUser.find_or_create_one(ac_id, at_id, current_user.id, nil, true)
      LogAction.access_webconference(academic_allocation_id: ac_id, academic_allocation_user_id: acu.try(:id), user_id: current_user.id, ip: request.headers['Solar'], allocation_tag_id: at_id, description: webconference.attributes) if AllocationTag.find(at_id).is_student_or_responsible?(current_user.id)

      render json: { success: true, url: url }
    end  
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  def list_access
    @webconference = Webconference.find(params[:id])
    authorize! :list_access, Webconference, { on: at_id = active_tab[:url][:allocation_tag_id] || params[:at_id] || @webconference.allocation_tags.map(&:id), accepts_general_profile: true }

    academic_allocations_ids = (@webconference.shared_between_groups ? @webconference.academic_allocations.map(&:id) : @webconference.academic_allocations.where(allocation_tag_id: at_id).first.try(:id))
    ats = AllocationTag.where(id: at_id).map(&:related)

    @logs = @webconference.get_access(academic_allocations_ids, ats, {})
    @logs_support = @webconference.get_support_attendance(academic_allocations_ids)

    @researcher = current_user.is_researcher?(ats)
    @too_old    = @webconference.initial_time.to_date < Date.parse(YAML::load(File.open('config/webconference.yml'))['participant_log_date']) rescue false

    @can_evaluate = can? :evaluate, Webconference, {on: at_id}
    @can_comment = can? :create, Comment, {on: [@allocation_tags]}
    acs = AcademicAllocation.where(id: academic_allocations_ids)
    @evaluative = @can_evaluate && (acs.where(evaluative: true).size == acs.size)
    @frequency = @can_evaluate && (acs.where(frequency: true).size == acs.size)

    AcademicAllocationUser.set_new_after_evaluation(at_id, @webconference.id, 'Webconference', @logs.map(&:user_id).uniq, nil, false)

    render partial: 'list_access'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  # Retorna a lista de atendimentos do Log_actions
  def list_support_help
    @webconference = Webconference.find(params[:id])
    @at_id         = active_tab[:url][:allocation_tag_id] || params[:at_id] || @webconference.allocation_tags.map(&:id)
    authorize! :see_help_requests, Webconference, { on: @at_id, accepts_general_profile: true }

    academic_allocations_ids = (@webconference.shared_between_groups ? @webconference.academic_allocations.map(&:id) : @webconference.academic_allocations.where(allocation_tag_id: @at_id ).first.try(:id))

    @logs = @webconference.get_support_attendance(academic_allocations_ids)

    render partial: 'list_support_help'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  def user_access
    @webconference = Webconference.find(params[:id])
    begin
      authorize! :list_access, Webconference, { on: @allocation_tag_id = active_tab[:url][:allocation_tag_id] || params[:at_id] || @webconference.allocation_tags.map(&:id), accepts_general_profile: true }
    rescue
      raise CanCan::AccessDenied unless params.include?(:user_id) && params[:user_id].to_i == current_user.id
    end

    academic_allocations_ids = (@webconference.shared_between_groups ? @webconference.academic_allocations.map(&:id) : @webconference.academic_allocations.where(allocation_tag_id: @allocation_tag_id).first.try(:id))
    ats = AllocationTag.where(id: @allocation_tag_id).map(&:related)
    @score_type = params[:score_type]

    @logs = @webconference.get_access(academic_allocations_ids, ats, {user_id: params[:user_id]})
    @user = User.find(params[:user_id])

    @researcher = current_user.is_researcher?(ats)
    @too_old    = @webconference.initial_time.to_date < Date.parse(YAML::load(File.open('config/webconference.yml'))['participant_log_date']) rescue false

    @can_evaluate = can? :evaluate, Webconference, {on: @allocation_tag_id}
    acs = AcademicAllocation.where(id: academic_allocations_ids)
    @evaluative = (acs.where(evaluative: true).size == acs.size)
    @frequency = (acs.where(frequency: true).size == acs.size)

    @academic_allocation = acs.where(allocation_tag_id: @allocation_tag_id).first

    @acu = AcademicAllocationUser.find_one(@academic_allocation.id, params[:user_id],nil, false, @can_evaluate)
    
    @maxwh = acs.first.max_working_hours
    @back = params.include?(:back)

    render partial: 'user_access'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { success: false, alert: t('webconferences.error.access') }, status: :unprocessable_entity
  end

  def get_record
    if Exam.verify_blocking_content(current_user.id)
      render text: t('exams.restrict')
    else
      @webconference = Webconference.find(params[:id])
      api = @webconference.bbb_prepare
      @at_id         = active_tab[:url][:allocation_tag_id] || params[:at_id] || @webconference.allocation_tags.map(&:id)

      raise CanCan::AccessDenied if current_user.is_researcher?(AllocationTag.where(id: @at_id).map(&:related).flatten.uniq)

      begin
        authorize! :index, Webconference, { on: @at_id, accepts_general_profile: true }
      rescue
        authorize! :preview, Webconference, { on: @at_id, accepts_general_profile: true }
      end

      @can_remove_record = (can? :manage_record, Webconference, { on: @webconference.academic_allocations.map(&:allocation_tag_id).flatten, accepts_general_profile: true }) || current_user.id == @webconference.user_id

      raise 'offline'          unless bbb_online?(api)
      raise 'still_processing' unless @webconference.is_over?

      @recordings = @webconference.recordings([], (@at_id.class == Array ? nil : @at_id))
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unprocessable_entity
  rescue URI::InvalidURIError
    render json: { success: false, alert: t('webconferences.list.removed_record') }, status: :unprocessable_entity
  rescue => error
    error_message = error == CanCan::AccessDenied ? t(:no_permission) : (I18n.translate!("webconferences.error.#{error}", raise: true) rescue t("webconferences.error.removed_record"))
    render text: error_message
    # render_json_error(error, 'webconferences.error')
  end

  # Alterna a sessão do suporte webconferência
  def support_help_session
    if session[:support_connect].nil? || session[:support_connect] == false
      session[:support_connect] = true
    else
      session[:support_connect] = false
    end
    respond_to do |format|
      format.json { render json: {session: session[:support_connect] } }
    end
  end

  # Tela de escolha da web para o atendimento do suporte
  def support_help
    @webconferences_online = params[:web_online].nil? ? nil : Webconference.find(params[:web_online])
  end

  # Atendimento do chamado de suporte da webconferência
  def support_help_attendance
    ac_id = params[:ac_id]
    # Mudança do status da academic_allocation (Support_Help_Success)
    Webconference.set_status_support_help(ac_id, Support_Help_Success)
    # Registro do atendimento no Log
    LogAction.create(log_type: LogAction::TYPE[:webconferece_support_attendance], user_id: current_user.id, description: "Support for webconference", academic_allocation_id: ac_id)

    respond_to do |format|
      format.json { render json: {response: "OK" } }
    end
  end

  private

  def save_log(webconference, acs=nil)
    logs = []

    if acs.nil?
      logs << { allocation_tag_id: params[:at], description: "webconference: #{webconference.id} removing recording #{params[:recordID]} by user #{current_user.id}" }
    else
      acs.each do |ac|
        logs << { academic_allocation_id: ac.id, description: "webconferences: #{ac.academic_tool_id} removing all recordings by user #{current_user.id}" }
      end
    end

    params_log = { log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, ip: get_remote_ip }

    logs.each do |log|
      LogAction.create(params_log.merge!(log))
    end
  end

  # Muda o status da academic_allocation para Support_Help_Fail se a webconferência encerrar e não tiver atendimento
  def close_expired_support_help
    AcademicAllocation.joins("JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Webconference'").where( support_help: Support_Help_Request ).where("NOW() > webconferences.initial_time + webconferences.duration* interval '1 min'").update_all( support_help: Support_Help_Fail )
  end

  def webconference_params
    params.require(:webconference).permit(:description, :duration, :initial_time, :title, :is_recorded, :shared_between_groups, :server)
  end

end

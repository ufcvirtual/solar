class AllocationsController < ApplicationController
  include AllocationsHelper
  include SysLog::Actions

  layout false, except: :index

  authorize_resource except: [:destroy, :designates, :create_designation, :activate, :deactivate]

  # GET /allocations/enrollments
  # GET /allocations/enrollments.json
  def index
    groups = groups_that_user_have_permission.map(&:id)

    @allocations = []
    @status = params[:status] || 0 # pendentes

    @allocations = Allocation.enrollments(status: @status, group_id: groups, user_search: params[:user_search]).paginate(page: params[:page]) if groups.any?

    render partial: "enrollments", layout: false if params[:filter]
  end

  # GET /allocations/1
  # GET /allocations/1.json
  def show
    @allocation = Allocation.find(params[:id])
  end

  # GET /allocations/1/edit
  def edit
    @allocation   = Allocation.find(params[:id])
    @status_hash  = status_hash_of_allocation(@allocation.status)
    @change_group = not([Allocation_Cancelled, Allocation_Rejected].include?(@allocation.status))

    # transicao entre grupos apenas da mesma oferta
    @groups = @change_group ? Group.where(offer_id: @allocation.group.offer_id) : @allocation.group
  end

  # Usado na matrícula
  def create
    group = Group.find(params[:group_id])

    if @allocation = group.request_enrollment(current_user)
      render json: {id: @allocation.id, notice: t('allocations.success.enrollm_request')}
    else
      render json: {alert: t('allocations.error.enrollm_request')}, status: :unprocessable_entity
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    @allocations = Allocation.where(id: params[:id].split(","))

    group, new_status = if params[:multiple].present? and params[:enroll].present?
      [nil, Allocation_Activated]
    else
      [Group.find_by_id(params[:allocation][:group_id]), params[:allocation][:status]]
    end

    change_status_from_allocations(@allocations, new_status, group)

    render partial: "enrollments", notice: t('allocations.manage.enrollment_successful_update'), layout: false
  rescue ActiveRecord::RecordNotUnique
    render json: {sucess: false, alert: t('allocations.error.student_already_in_group')}, status: :unprocessable_entity
  rescue => error
    request.format = :json
    raise error.class
  end

  # DELETE /allocations/1/cancel
  # DELETE /allocations/1/cancel_request
  def destroy
    authorize! :cancel, Allocation if not params.include?(:type)
    authorize! :cancel_request, Allocation if params.include?(:type) and params[:type] == 'request'

    @allocation = Allocation.find(params[:id])

    begin
      error = false
      raise CanCan::AccessDenied if (@allocation.user_id != current_user.id and params[:type] == "request") or
        ((@allocation.profile_id == Profile.student_profile or @allocation.profile.has_type?(Profile_Type_Basic)) and params.include?(:profile))

      if params.include?(:type) and params[:type] == 'request' and @allocation.status == Allocation_Pending
        @allocation.destroy
        message = (params.include?(:profile) ? t("allocations.success.request_canceled") : t(:enrollm_request_cancel_message))
      else
        @allocation.update_attribute(:status, Allocation_Cancelled)
        message = (params.include?(:profile) ? t("allocations.success.profile_canceled") : t(:enrollm_cancelled_message))
      end
    rescue CanCan::AccessDenied
      error = true
      message = t(:no_permission)
    rescue
      message = (params.include?(:profile) ? t("allocations.error.cancel_request") : t(:enrollm_not_cancelled_message))
      error   = true
    end

    respond_to do |format|
      unless error
        format.html { redirect_to(:back, notice: message) }
        format.json { render json: {success: :ok, notice: message} }
      else
        format.html { redirect_to(:back, alert: message) }
        format.json { render json: {success: false, alert: message}, status: :unprocessable_entity }
      end
    end
  end








  # Usado na alocacao de usuarios
  def create_designation
    allocation_tags_ids = if (params.include?(:profile) and not(params[:profile].blank?) and Profile.find(params[:profile]).has_type?(Profile_Type_Admin))
      [nil]
    else
      AllocationTag.get_by_params(params)[:allocation_tags]
    end

    authorize! :create_designation, Allocation if params[:admin]
    authorize! :create_designation, Allocation, on: allocation_tags_ids unless params[:admin] or params.include?(:request)

    profile = params.include?(:profile) ? params[:profile] : Profile.student_profile
    status  = params.include?(:status) ? params[:status]  : Allocation_Pending
    user    = (params.include?(:user_id) and not(params.include?(:request))) ? params[:user_id] : current_user.id
    raise t("allocations.error.student_or_basic") if profile == Profile.student_profile or (not(profile.blank?) and Profile.find(profile).has_type?(Profile_Type_Basic))
    raise t("allocations.error.profile") if params[:profile].blank?

    allocations = Array.new
    ok = allocate(allocation_tags_ids.split(" ").flatten, allocations, user, profile, status)

    unless params.include?(:request)
      case ok
        when nil; render json: {success: false, message: t("allocations.warning.already_active"), type: "warning"}
        when true; render :designates, status: 200
        when false; render json: {success: false, alert: t("allocations.error.not_allocated")}, status: :unprocessable_entity
      end
    else
      case ok
        when nil; render json: {success: false, message: t("allocations.warning.already_active"), type: "warning"}
        when true; render json: {success: true, message: t("allocations.success.requested"), type: "notice"}
        when false; render json: {success: false, alert: t("allocations.error.not_allocated")}, status: :unprocessable_entity
      end
    end
  rescue => error
    render json: {success: false, alert: error.message}, status: :unprocessable_entity
  ensure
    @allocations = allocations # used at log generation
  end












  # GET /allocations/designates
  # GET /allocations/designates.json
  def designates
    @allocation_tags_ids = if (not params.include?(:admin) or params.include?(:allocation_tags_ids))
       params.include?(:allocation_tags_ids) ? params[:allocation_tags_ids] : []
    else
      AllocationTag.get_by_params(params)[:allocation_tags].join(" ")
    end

    begin
      authorize! :create_designation, Allocation, {on: @allocation_tags_ids, accepts_general_profile: true}

      level        = (params[:permissions] != "all" and (not params.include?(:admin))) ? "responsible" : nil
      level_search = level.nil? ? ("not(profiles.types & #{Profile_Type_Basic})::boolean") : ("(profiles.types & #{Profile_Type_Class_Responsible})::boolean")

      @allocations = Allocation.all(
        joins: [:profile, :user],
        conditions: ["#{level_search} and allocation_tag_id IN (?)", @allocation_tags_ids.split(" ").flatten],
        order: ["users.name", "profiles.name"])

      @admin = params[:admin]
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    end
  end

  def search_users
    @text_search, @admin = URI.unescape(params[:user]), params[:admin]

    text = [@text_search.split(" ").compact.join(":*&"), ":*"].join unless params[:user].blank?
    @allocation_tags_ids = params[:allocation_tags_ids]
    @users = User.find_by_text_ignoring_characters(text).paginate(page: params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def deactivate
    @allocation  = Allocation.find(params[:id])
    @text_search = params[:text_search]

    begin
      if current_user.is_admin?
        authorize! :deactivate, Allocation
      else
        authorize! :deactivate, @allocation
      end

      raise "error" unless @allocation.update_attribute(:status, Allocation_Cancelled)

      render json: {success: true}
    rescue
      render json: {success: false, alert: t(:not_deactivated, scope: [:allocations, :error])}, status: :unprocessable_entity
    end
  end

  def activate
    @allocation = Allocation.find(params[:id])
    allocation_tag_id = @allocation.allocation_tag_id

    begin
      if current_user.is_admin?
        authorize! :activate, Allocation
      else
        authorize! :activate, @allocation
      end

      raise "error" unless @allocation.update_attribute(:status, Allocation_Activated)

      render json: {success: true, notice: t("allocations.success.activated")}
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
    rescue
      render json: {success: false, alert: t(:not_activated, scope: [:allocations, :error])}, status: :unprocessable_entity
    end
  end

  def reactivate
    @allocation = Allocation.find(params[:id])
    offer = @allocation.offer || @allocation.group.offer
    ok = (offer.enrollment_start_date.to_date..(offer.enrollment_end_date.try(:to_date) || offer.end_date.to_date)).include?(Date.today)

    if ok and @allocation.update_attribute(:status, Allocation_Pending_Reactivate)
      render json: {id: @allocation.id, notice: t('allocations.success.enrollm_request')}
    else
      render json: {alert: t('allocations.error.enrollm_request')}, status: :unprocessable_entity
    end
  end

  def accept_or_reject
    @allocation = Allocation.find(params[:id])

    if current_user.is_admin?
      authorize! :accept_or_reject, Allocation
    else
      authorize! :accept_or_reject, Allocation, on: [@allocation.allocation_tag_id]
    end

    if params.include?(:undo)
      message = t("allocations.success.undone_action")
      @allocation.update_attribute(:status, Allocation_Pending)
    else
      path    = @allocation.allocation_tag.nil? ? "" : t("allocations.success.allocation_tag_path", path: @allocation.allocation_tag.try(:info))
      action  = params[:accept] ? t("allocations.success.accepted") : t("allocations.success.rejected")
      message = t("allocations.success.request_message", user_name: @allocation.user.name, profile_name: @allocation.profile.name, path: path, action: action,
        undo_url: view_context.link_to(t("allocations.undo_action"), "#", id: :undo_action, :"data-link" => undo_action_allocation_path(@allocation)))
      @allocation.update_attribute(:status, (params[:accept] ? Allocation_Activated : Allocation_Rejected))
    end

    render json: {success: true, notice: message}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("allocations.manage.enrollment_unsuccessful_update")}, status: :unprocessable_entity
  end

  private

    def change_status_from_allocations(allocations, new_status, group = nil)
      # muda todos os status ao mesmo tempo mandando emails
      allocations.each do |a|
        a = user_change_group(a, group) if not(group.nil?) and a.group.id != group.id # mudança de turma

        a.update_attribute(:status, new_status)
        send_email_to_enrolled_user(a) if new_status == Allocation_Activated
      end
    end

    def user_change_group(allocation, new_group)
      # cancela na turma anterior e cria uma nova alocação na nova
      Allocation.transaction do
        new_allocation = allocation.dup
        allocation.update_attribute(:status, Allocation_Cancelled)

        new_allocation.allocation_tag_id = new_group.allocation_tag.id
        new_allocation.save!
      end

      new_allocation
    end

    def send_email_to_enrolled_user(allocation)
      Thread.new do
        Mutex.new.synchronize {
          Notifier.enrollment_accepted(allocation.user.email, allocation.group.code_semester).deliver
        }
      end
    end

    def groups_that_user_have_permission
      profiles = current_user.profiles_with_access_on("index", "allocations").pluck(:id)
      groups = current_user.allocations.where(profile_id: profiles).where("allocation_tag_id IS NOT NULL").map { |a| a.groups }.flatten.uniq.compact
    end

    def status_hash_of_allocation(allocation_status)
      case allocation_status
        when Allocation_Pending, Allocation_Pending_Reactivate
          status_hash.select { |k,v| [allocation_status, Allocation_Activated, Allocation_Rejected].include?(k) }
        when Allocation_Activated
          status_hash.select { |k,v| [allocation_status, Allocation_Cancelled].include?(k) }
        when Allocation_Cancelled, Allocation_Rejected
          status_hash.select { |k,v| [allocation_status, Allocation_Activated].include?(k) }
      end
    end

    def allocate(allocation_tags_ids, allocations, user_id, profile, status)
      success = true
      [allocation_tags_ids].flatten.each do |allocation_tag_id|
        allocation = Allocation.where(allocation_tag_id: allocation_tag_id, user_id: user_id, profile_id: profile).first_or_initialize
        unless allocation.new_record? # existe alocação
          if allocation.status != Allocation_Activated # não ativada
            allocation.update_attribute(:status, Allocation_Pending_Reactivate)
          elsif [allocation_tags_ids].flatten.size == 1
            success = nil
          end
        else # não existe alocação
          allocation.status = status
          success = false unless allocation.save
        end
        allocations << allocation if success
      end
    rescue
      success = false
    ensure
      return success
    end

end

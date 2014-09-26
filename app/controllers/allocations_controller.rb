class AllocationsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  before_filter :allocations_to_designate, only: [:create_designation, :profile_request]



  before_filter only: [:show, :edit, :update] do |controller|
    @allocation = Allocation.find(params[:id])
  end



  ## GERENCIAR MATRICULA



  # GET /allocations/enrollments
  # GET /allocations/enrollments.json

  ## manage_list

  def index
    authorize! :manage_enrolls, Allocation

    groups = groups_that_user_have_permission.map(&:id)

    @allocations = []
    @status = params[:status] || 0 # pendentes

    @allocations = Allocation.enrollments(status: @status, group_id: groups, user_search: params[:user_search]).paginate(page: params[:page]) if groups.any?

    # raise "#{@allocations}"

    render partial: "enrollments", layout: false if params[:filter]
  end

  # GET /allocations/1
  # GET /allocations/1.json
  def show
    authorize! :manage_enrolls, Allocation
  end

  # GET /allocations/1/edit
  def edit
    authorize! :manage_enrolls, Allocation
  end

  # permissao para aceitar/modificar alocacao
  # aluno teria permissao apenas para pedir/cancelar


  ## aqui ele manda o id do status
  ## em update ele manda uma informacao (pode ser que seja melhor assim)

  # PUT manage_enrolls
  def manage_enrolls

    ## nao deveria olhar as ats?

    authorize! :manage_enrolls, Allocation

    @allocations = Allocation.where(id: params[:id].split(","))

    group, new_status = if params[:multiple].present? and params[:enroll].present?
      [nil, Allocation_Activated]
    else
      [Group.find_by_id(params[:allocation][:group_id]), params[:allocation][:status]]
    end

    change_status_from_allocations(@allocations, new_status, group)

    render partial: "enrollments", notice: t('allocations.manage.enrollment_successful_update'), layout: false
  end






  ## PEDIR MATRICULA

  ## aqui ficara pedir perfil tb

  def create
    group = Group.find(params[:group_id])

    if @allocation = group.request_enrollment(current_user)
      render json: {success: true, msg: t('allocations.success.enrollm_request'), id: @allocation.id}
    else
      render json: {success: false, msg: t('allocations.error.enrollm_request')}, status: :unprocessable_entity
    end
  end




  ## PEDIR PERFIL



  # como o status das outras chamadas sao passados por parametro, o usuario poderia add qualquer perfil pra ele
  def profile_request
    authorize! :create, Allocation

    allocate_and_render_result(current_user, params[:profile], Allocation_Pending, t('allocations.success.requested'))
  end




  ## EDITOR - CONTEUDO - ALOCACOES
  ## ADMIN - INDICAR USUARIOS




  # GET /allocations/designates
  # GET /allocations/admin_designates
  def designates

    @allocation_tags_ids = if (not(params[:admin].present?) or params[:allocation_tags_ids].present?)
       params[:allocation_tags_ids] || []
    else
      AllocationTag.get_by_params(params)[:allocation_tags].join(" ")
    end

    begin
      # authorize! :create_designation, Allocation, {on: @allocation_tags_ids, accepts_general_profile: true}
      authorize! :manage_profiles, Allocation, {on: @allocation_tags_ids, accepts_general_profile: true}

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





  def create_designation
    # if params[:admin] and current_user.is_admin?
    #   authorize! :create_designation, Allocation
    # else
    #   authorize! :create_designation, Allocation, on: @allocation_tags_ids
    # end

    if params[:admin] and current_user.is_admin?
      authorize! :manage_profiles, Allocation
    else
      authorize! :manage_profiles, Allocation, on: @allocation_tags_ids
    end


    # verificar quando for perfil sem alocacao em at

    allocate_and_render_result(User.find(params[:user_id]), params[:profile], params[:status])
  end

  def search_users
    authorize! :manage_profiles, Allocation

    @text_search, @admin = URI.unescape(params[:user]), params[:admin]

    text = [@text_search.split(" ").compact.join(":*&"), ":*"].join if params[:user].present?
    @allocation_tags_ids = params[:allocation_tags_ids]
    @users = User.find_by_text_ignoring_characters(text).paginate(page: params[:page])
  end


  ## EDITOR - CONTEUDO - ALOCACOES
  ## ADMIN - INDICAR USUARIOS
  ## ADMIN APROVAR PERFIS


  # aluno pode cancel
  # admin/editor change allocation

  def update
    ## verifica se tem permissao em manage_profiles ou se tem em criar e eh o proprio usuario que quer cancelar a matricula

    @allocation = Allocation.find(params[:id])



    if current_user.is_admin?
      authorize! :manage_profiles, Allocation
    else
      # editor/aluno (editor vai acessar a alocacao mesmo???)
      authorize! :manage_profiles, @allocation, on: [@allocation.allocation_tag_id] unless [:reactivate, :cancel, :cancel_request, :cancel_profile_request].include?(params[:type])
    end


    # if params[:profile_request] and [:accept, :reject].include?(params[:type]) # accept_or_reject

    #   # authorize! :accept_or_reject, Allocation, on: [@allocation.allocation_tag_id]
    #   authorize! :manage_profiles, Allocation, on: [@allocation.allocation_tag_id]

    # else
    #   ## admin => aceitar/rejeitar pedido de perfil
    #   authorize! :manage_profiles, current_user.is_admin? ? Allocation : @allocation unless [:cancel, :cancel_request, :cancel_profile_request].include?(params[:type])
    # end


    if change_to_new_status(@allocation, params[:type])
      render json: {success: true, msg: success_msg, id: @allocation.id}
    else
      render json: {success: false, msg: t(params[:type], scope: 'allocations.change_status.error')}, status: :unprocessable_entity
    end
  end






  private

    def success_msg
      # aceita/rejeita pedido de perfil
      msg = if params[:profile_request] and [:accept, :reject].include?(params[:type])
        path    = t("allocations.success.allocation_tag_path", path: @allocation.allocation_tag.info) rescue ''
        action  = params[:type] == :accept ? t("allocations.success.accepted") : t("allocations.success.rejected")

        t("allocations.success.request_message", user_name: @allocation.user.name, profile_name: @allocation.profile.name, path: path, action: action,
          undo_url: view_context.link_to(t("allocations.undo_action"), "#", id: :undo_action, :"data-link" => undo_action_allocation_path(@allocation)))
      else
        t(params[:type], scope: 'allocations.change_status.success')
      end
    end

    # quem tem permissao em activate, deactivate, reactivate

    def change_to_new_status(allocation, type)
      case type
        when :activate
          allocation.activate!
        when :deactivate
          allocation.deactivate!
        when :reactivate

          raise CanCan::AccessDenied if allocation.user_id != current_user.id
          allocation.request_reactivate!

        when :cancel, :cancel_request, :cancel_profile_request

          # apenas quem pede matricula/perfil pode cancelar pedido / perfil de aluno e basico nao pode ser cancelado pela lista de perfis
          raise CanCan::AccessDenied if allocation.user_id != current_user.id or
            (type == :cancel_profile_request and (allocation.profile_id == Profile.student_profile or allocation.profile.has_type?(Profile_Type_Basic)))
          allocation.cancel!

        when :reject
          allocation.reject!
        when :accept
          allocation.activate!
        when :pending
          allocation.pending!
      end # case
      allocation.errors.empty?
    end

    def change_status_from_allocations(allocations, new_status, group = nil)
      # muda todos os status ao mesmo tempo mandando emails
      allocations.each do |a|
        a = user_change_group(a, group) if not(group.nil?) and a.group.id != group.id # mudança de turma

        a.update_attributes(status: new_status)
        send_email_to_enrolled_user(a) if new_status == Allocation_Activated
      end
    end

    def user_change_group(allocation, new_group)
      # cancela na turma anterior e cria uma nova alocação na nova
      new_allocation = allocation.dup
      Allocation.transaction do
        # allocation.update_attributes(status: Allocation_Cancelled)
        allocation.cancel!

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
      profiles = current_user.profiles_with_access_on("manage_enrolls", "allocations").pluck(:id)
      groups = current_user.allocations.where(profile_id: profiles).where("allocation_tag_id IS NOT NULL").map { |a| a.groups }.flatten.uniq.compact
    end

    def allocations_to_designate
      @allocation_tags_ids = if (params[:profile].present? and Profile.find(params[:profile]).has_type?(Profile_Type_Admin))
        [nil]
      else
        AllocationTag.get_by_params(params)[:allocation_tags]
      end
    end

    def allocate_and_render_result(user, profile, status, success_msg = t("allocations.success.allocated"))
      result = user.allocate_in(allocation_tag_ids: @allocation_tags_ids.split(" ").flatten, profile: profile, status: status)

      @allocations = result[:success] # used at log generation

      render_result_designate(result, success_msg)
    end

    def render_result_designate(result, success_msg)
      if result[:error].any?
        alert = result[:error].first.errors.full_messages.uniq.join(', ')
        render json: {success: false, msg: alert}, status: :unprocessable_entity # apresenta apenas o erro do primeiro problema
      else
        render json: {success: true, msg: success_msg}
      end
    end

end

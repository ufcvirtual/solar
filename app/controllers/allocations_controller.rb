# encoding: UTF-8
class AllocationsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  before_filter only: [:enroll_request, :profile_request] do
    authorize! :create, Allocation
  end

  before_filter only: [:create_designation, :profile_request] do
    @allocation_tags_ids = AllocationTag.get_by_params(params)[:allocation_tags]
  end

  before_filter only: [:show, :edit, :update] do
    @allocation = Allocation.find(params[:id])

    # editor/aluno
    # pedir matricula e perfil nao precisa de permissao
    authorize! :manage_profiles, @allocation, { on: [@allocation.allocation_tag_id], accepts_general_profile: true } unless params[:profile_request] || params[:enroll_request]
  end


  ## GERENCIAR MATRICULA


  # GET /allocations/enrollments
  # GET /allocations/enrollments.json
  def index
    authorize! :manage_enrolls, Allocation

    groups = groups_that_user_have_permission.map(&:id)

    @allocations = []
    @status = params[:status] || 0 # pendentes

    @allocations = Allocation.enrollments(status: @status, group_id: groups, user_search: params[:user_search]).paginate(page: params[:page]) if groups.any?

    render partial: 'enrollments', layout: false if params[:filter]
  end

  # GET /allocations/1
  # GET /allocations/1.json
  def show
  end

  # GET /allocations/1/edit
  def edit
  end

  ## matricular varios de uma vez /  mudar aluno de turma aceitando matricula

  # PUT manage_enrolls
  def manage_enrolls
    allocations = Allocation.where(id: params[:id].split(','))
    authorize! :manage_enrolls, Allocation, on: allocations.pluck(:allocation_tag_id)

    group, new_status = if params[:multiple].present? && params[:enroll].present?
                          [nil, Allocation_Activated]
                        else
                          [Group.find_by_id(params[:allocation][:group_id]), params[:allocation][:status].to_i]
                        end

    @allocations = Allocation.change_status_from(allocations, new_status, group: group, by_user: current_user)

    render partial: 'enrollments', notice: t('allocations.manage.enrollment_successful_update'), layout: false
  rescue => error
    request.format = :json
    raise error.class
  end

  ## PEDIR MATRICULA

  def enroll_request
    group = Group.find(params[:group_id])
    render_result_designate(group.request_enrollment(current_user), t('allocations.request.success.enroll'))
  end

  ## PEDIR PERFIL

  def profile_request
    allocate_and_render_result(current_user, params[:profile_id], Allocation_Pending, t('allocations.request.success.profile'))
  end

  ## EDITOR - CONTEUDO - ALOCACOES
  ## ADMIN - INDICAR USUARIOS

  # GET /allocations/designates
  # GET /allocations/admin_designates
  def designates
    @allocation_tags_ids = atgs_to_designates
    authorize! :manage_profiles, Allocation, on: @allocation_tags_ids, accepts_general_profile: true

    @admin = params[:admin]
    @allocations = Allocation.list_for_designates((@allocation_tags_ids.nil? ? [] : @allocation_tags_ids.split(' ')), @admin)
  rescue => error
    request.format = :json
    raise error.class
  end

  def create_designation
    authorize! :manage_profiles, Allocation, { on: [@allocation_tags_ids], accepts_general_profile: true }

    allocate_and_render_result(User.find(params[:user_id]), params[:profile_id], params[:status])
  rescue
    render json: { success: false, msg: t(:no_permission) }, status: :unprocessable_entity
  end

  def search_users
    authorize! :manage_profiles, Allocation

    @text_search, @admin = URI.unescape(params[:user]), params[:admin]

    text = [@text_search.split(' ').compact.join('%'), '%'].join if params[:user].present?
    @allocation_tags_ids = params[:allocation_tags_ids]
    @users = User.find_by_text_ignoring_characters(text).paginate(page: params[:page])
  end

  ## EDITOR - CONTEUDO - ALOCACOES
  ## ADMIN - INDICAR USUARIOS
  ## ADMIN APROVAR PERFIS

  # aluno pode cancel
  # admin/editor change allocation
  def update
    if @allocation.change_to_new_status(params[:type], current_user)
      render json: { success: true, msg: success_msg, id: @allocation.id }
    else
      render json: { success: false, msg: t(params[:type], scope: 'allocations.request.error') }, status: :unprocessable_entity
    end
  end

  def show_profile
    @allocation_tags_ids = params[:allocation_tags_ids]
    @admin = params[:admin]
    render partial: 'show', locals: { allocation: Allocation.find(params[:id]) }
  end

  private

  def success_msg
    if params[:acccept_or_reject_profile] # aceita/rejeita pedido de perfil
      path = t('allocations.allocation_tag_path', path: @allocation.allocation_tag.info) rescue ''
      action = params[:type] == :accept ? t('allocations.accepted') : t('allocations.rejected')

      t('allocations.request.success.accept_reject_msg',
        user_name: @allocation.user.name, profile_name: @allocation.profile.name, path: path, action: action,
        undo_url: view_context.link_to(t('allocations.undo_action'), '#', id: :undo_action, :"data-link" => undo_action_allocation_path(@allocation)))
    else
      t(params[:type], scope: 'allocations.request.success')
    end
  end

  def groups_that_user_have_permission
    profiles = current_user.profiles_with_access_on('manage_enrolls', 'allocations').map(&:id)
    current_user.allocations.where(profile_id: profiles).where('allocation_tag_id IS NOT NULL').map(&:groups).flatten.uniq.compact
  end

  def allocate_and_render_result(user, profile, status, success_message = t('allocations.request.success.allocated'))
    result = user.allocate_in(allocation_tag_ids: @allocation_tags_ids.split(' ').uniq.flatten, profile: profile, status: status, by_user: current_user.id)
    render_result_designate(result, success_message)
  end

  def render_result_designate(result, success_message)
    @allocations = result[:success] # used at log generation

    if result[:error].any?
      # apresenta apenas o erro do primeiro problema
      render json: { success: false, msg: result[:error].first.errors.full_messages.uniq.join(', ') }, status: :unprocessable_entity
    else
      render json: { success: true, msg: success_message, id: result[:success].map(&:id) }
    end
  end

  def atgs_to_designates
    if !params[:admin].present? || params[:allocation_tags_ids].present?
      params[:allocation_tags_ids] || []
    else
      AllocationTag.get_by_params(params)[:allocation_tags].join(' ')
    end
  end
end

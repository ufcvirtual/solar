class DigitalClassesController < ApplicationController

  include EdxHelper
  include SysLog::Actions

  before_filter :verify_digital_class
  before_filter :prepare_for_group_selection, only: :index
  before_filter :get_groups_by_allocation_tags, only: [:new, :create, :list]

  layout false, except: [:index, :update_members_and_roles_page]
  before_filter only: [:edit, :update] do |controller|
    @groups = Group.get_group_from_lesson(DigitalClass.get_lesson(params[:id]))
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, DigitalClass, on: @allocation_tags_ids
    Group.verify_or_create_at_digital_class(@groups)
    @digital_class_lessons = []

    @groups.each do |group|
      lessons = DigitalClass.get_lessons_by_directory(group.try(:digital_class_directory_id)) rescue []

      lessons.each do |ls|
        @digital_class_lessons << { groups: Group.get_group_from_lesson(ls), lesson: ls } unless @digital_class_lessons.any? {|h| h[:lesson]['id'] == ls['id']}
      end 
    end 
    #redirect_to url_redirect, flash: flash
  rescue => error
    request.format = :json
  end

  def new
    authorize(:create)

    if params[:lesson]
      ats = AllocationTag.where(id: @allocation_tags_ids).map(&:related).flatten.uniq
      @lmodules = LessonModule.joins(:academic_allocations, :lessons).where(academic_allocations: {allocation_tag_id: ats }).uniq
      render :lesson
    end
  end

  def create
    authorize(:create)

    dc_user_id = current_user.verify_or_create_at_digital_class    
    directories_ids = Group.verify_or_create_at_digital_class(@groups)
    @groups.map(&:allocation_tag).each do |at|
      DigitalClass.verify_and_create_member(current_user, at)
    end

    if params.include?(:lessons)
      params[:lessons].each do |lesson_id|
        lesson = Lesson.find(lesson_id.to_i)
        response = DigitalClass.create_lesson(directories_ids.join(','), dc_user_id, { name: lesson.name, description: lesson.description })
        create_log(response, @allocation_tags_ids)  
      end
    else
      response = DigitalClass.create_lesson(directories_ids.join(','), dc_user_id, digital_class_params)
      create_log(response, @allocation_tags_ids)
    end

    render :new
  end

  def update_members_and_roles_page
    authorize! :update_members_and_roles, DigitalClass
    @types = ((!EDX.nil? && EDX['integrated']) ? CurriculumUnitType.all : CurriculumUnitType.where('id <> 7'))
   rescue => error
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def update_members_and_roles
    raise 'unavailable' unless DigitalClass.available?

    allocation_tags = AllocationTag.get_by_params(params)
    authorize! :update_members_and_roles, DigitalClass, { on: allocation_tags[:allocation_tags].compact, accepts_general_profile: true }

    result = DigitalClass.update_multiple(params[:initial_date], allocation_tags)
    raise 'error' if !result

    render json: { success: true, notice: t('digital_classes.success_message') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'digital_classes')
  end

  def index
    allocation_tag_ids = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
    authorize! :index, DigitalClass, { on: allocation_tag_ids }

    @group = (active_tab[:url].include?(:allocation_tag_id)) ? AllocationTag.find(active_tab[:url][:allocation_tag_id]).group : Group.find(params[:group_id] || [])

    dc_directory_id = DigitalClass.get_directories_by_allocation_tag(AllocationTag.find_by_id(allocation_tag_ids))
    @digital_class = DigitalClass.get_lessons_by_directory(dc_directory_id[0]) unless dc_directory_id.blank?

    @can_see_access = can? :list_access, DigitalClass, { on: allocation_tag_ids }
    @can_edit = can? :list, DigitalClass, { on: allocation_tag_ids }

    render layout: false if params[:layout]
  end

  def authenticate
    allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
    authorize! :access, DigitalClass, { on: allocation_tag_id }
    at = AllocationTag.find_by_id(allocation_tag_id)

    # loga acesso - o id da lesson no dc fica na descricao, por nao existir no solar
    LogAction.access_digital_class_lesson(description: "#{params[:id].to_i}, #{params[:url]}", user_id: current_user.id, ip: request.remote_ip, allocation_tag_id: allocation_tag_id) if at.is_student_or_responsible?(current_user.id)

    # chama autenticacao
    redirect_to DigitalClass.access_authenticated(current_user, params[:url], [at])
  end

  def list_access
    dc_lesson_id = params["id"]
    allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
    authorize! :list_access, DigitalClass, { on: allocation_tag_id }

    @digital_class_lesson = DigitalClass.get_lesson(dc_lesson_id) unless dc_lesson_id.nil?
    @logs = DigitalClass.get_access(dc_lesson_id, allocation_tag_id)
    
    render partial: 'list_access'
  end

  def access
    authorize! :access, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]
    redirect_to DigitalClass.access_authenticated(current_user, params[:url], AllocationTag.where(id: @allocation_tags_ids.split(' ')))
  end

  def edit
    authorize(:update, @groups)
    @digital_class_lesson = DigitalClass.get_lesson(params[:id])
  rescue => error
    render text: t(:no_permission_groups)
  end

  def update
    authorize(:update, @groups)
    
    if response = DigitalClass.update_lesson(digital_class_params, params[:id])
      create_log(response, @allocation_tags_ids)
      render json: { success: true, notice: t('digital_classes.success.updated') }
    else
      render :edit
    end
  rescue => error
    render_json_error(error, 'digital_classes.error')
  end

  def destroy
    authorize(:destroy)
    authorize! :destroy, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]

    ret = DigitalClass.delete_lesson(params[:id])
    LogAction.where(description: params[:id], log_type: LogAction::TYPE[:access_digital_class_lesson]).delete_all if ret['success']

    render json: {success: true, notice: t('digital_classes.success.deleted')}
  rescue => error
    render_json_error(error, 'digital_classes.error')
  end

   # remove/add groups to a digital class lesson
  def change_tool
    groups = Group.where(id: params[:id].split(','))
    authorize! :change_tool, DigitalClass, on: [RelatedTaggable.where(group_id: params[:id].split(',')).pluck(:group_at_id)]
    directories_ids = Group.verify_or_create_at_digital_class(groups)

    if params[:type] == 'add'
      DigitalClass.add_lesson_to_directories(directories_ids, params['tool_id'])
    else
      params['tool_id'].split(',').each do |tool_id|
        if DigitalClass.count_directories_by_lesson_id(tool_id) > 1
          DigitalClass.remove_lesson_from_directories(directories_ids, tool_id)
        else
          DigitalClass.delete_lesson(tool_id)
        end
      end
    end

    render json: { success: true, notice: t("#{params[:type]}", scope: [:groups, :success]) }
  rescue ActiveRecord::RecordNotSaved
    render json: { success: false, alert: t(:academic_allocation_already_exists, scope: [:groups, :error]) }, status: :unprocessable_entity
  rescue => error
    error_message = I18n.translate!("#{error.message}", scope: [:groups, :error], :raise => true) rescue t('tool_change', scope: [:groups, :error])
    render json: { success: false, alert: error_message }, status: :unprocessable_entity
  end

  private

  def authorize(method, groups=[])
    @allocation_tags_ids = params.include?(:allocation_tags_ids) ? params[:allocation_tags_ids] : ((active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id)
    if [:update, :destroy].include?(method) && groups.any?
      authorize! method, DigitalClass, on: @groups.map(&:allocation_tag).flatten.map(&:id).flatten 
    else
      authorize! method, DigitalClass, on: @allocation_tags_ids
    end
  end

  def create_log(response, allocation_tags_ids)
    description = "digital_class: #{response.except('directories').as_json}"
    allocation_tags_ids.split(' ').flatten.each do |at|
      LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, ip: request.remote_ip, description: description, allocation_tag_id: at)
    end
  end
  
  def digital_class_params
    params.require(:digital_classes).permit(:name, :description)
  end

  def verify_digital_class
    unless DigitalClass.available?
      if params.include?(:allocation_tags_ids)
        render json: { alert: t('digital_classes.error.unavailable') }, status: :unprocessable_entity
      else
        redirect_to :back, alert: t('digital_classes.error.unavailable')
      end
    end
  end

end

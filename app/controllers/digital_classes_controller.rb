class DigitalClassesController < ApplicationController

  include EdxHelper
  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: :list
  before_filter :get_groups_by_allocation_tags, only: [:new, :create, :list]

  layout false, except: [:index, :update_members_and_roles_page]
  before_filter only: [:edit, :update] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
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
  rescue => error
    request.format = :json
  end

  def new
    authorize! :create, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]
  end

  def create
    authorize! :create, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]

    dc_user_id = current_user.verify_or_create_at_digital_class    
    directories_ids = Group.verify_or_create_at_digital_class(@groups)
    @groups.map(&:allocation_tag).each do |at|
      DigitalClass.verify_and_create_member(current_user, at)
    end

    redirect_url = DigitalClass.create_lesson(directories_ids.join(','), dc_user_id, digital_class_params)
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

    dc_directory_id = DigitalClass.get_directories_by_allocation_tag(AllocationTag.find_by_id(allocation_tag_ids))
    
    @digital_class = DigitalClass.get_lessons_by_directory(dc_directory_id[0]) unless (dc_directory_id.empty? or dc_directory_id.nil?)
  end

  def edit
    authorize! :edit, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @digital_class_lesson = DigitalClass.get_lesson(params[:id])
  end

  def update
    authorize! :update, DigitalClass, on:  @allocation_tags_ids = params[:allocation_tags_ids]
    
    if DigitalClass.update_lesson(digital_class_params, params[:id])
      render json: { success: true, notice: t('digital_classes.success.updated') }
    else
      render :edit
    end
  rescue => error
      request.format = :json
     # raise error.class
  end

  def destroy
    authorize! :destroy, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]
    DigitalClass.delete_lesson(params[:id])
    render json: {success: true, notice: t('digital_classes.success.deleted')}
  rescue => error
    request.format = :json
    raise error.class
  end

   # remove/add groups to a digital class lesson
  def change_tool
    groups = Group.where(id: params[:id].split(','))
    authorize! :change_tool, DigitalClass, on: [RelatedTaggable.where(group_id: params[:id].split(',')).pluck(:group_at_id)]
    directories_ids = Group.verify_or_create_at_digital_class(groups)

    if params[:type] == 'add'
      DigitalClass.add_lesson_to_directories(directories_ids, params['tool_id'])
    else
      DigitalClass.remove_lesson_from_directories(directories_ids, params['tool_id'])
    end

    render json: { success: true, notice: t("#{params[:type]}", scope: [:groups, :success]) }
  rescue ActiveRecord::RecordNotSaved
    render json: { success: false, alert: t(:academic_allocation_already_exists, scope: [:groups, :error]) }, status: :unprocessable_entity
  rescue => error
    error_message = I18n.translate!("#{error.message}", scope: [:groups, :error], :raise => true) rescue t('tool_change', scope: [:groups, :error])
    render json: { success: false, alert: error_message }, status: :unprocessable_entity
  end
  private
  
  def digital_class_params
    params.require(:digital_classes).permit(:name, :description)
  end

end

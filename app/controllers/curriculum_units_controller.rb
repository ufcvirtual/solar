class CurriculumUnitsController < ApplicationController

  include SysLog::Actions

  layout false, only: [:new, :edit, :create, :update]

  before_filter :prepare_for_group_selection, only: [:home, :participants, :informations]
  before_filter :curriculum_data, only: [:home, :informations, :participants]
  before_filter :ucs_for_list, only: [:list, :mobilis_list]

  load_and_authorize_resource only: [:edit, :update]

  def home
    authorize! :show, CurriculumUnit, { on: @allocation_tags_ids, read: true }
    @messages = Message.by_box(current_user.id, 'inbox', @allocation_tag_id, { only_unread: true })
    user_profiles     = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)
    @lessons_modules  = (user_profiles.include?(lessons: :show) ? [] : LessonModule.to_select(@allocation_tags_ids, current_user))
    @discussion_posts = list_portlet_discussion_posts(@allocation_tags_ids)
    @scheduled_events = (user_profiles.include?(agendas: :calendar) ? [] : Agenda.events(@allocation_tags_ids, nil, true))
    @researcher = current_user.is_researcher?(@allocation_tags_ids)
  end

  def index
    @type = CurriculumUnitType.find(params[:type_id])
    @curriculum_units = []

    if params[:combobox]
      if @type.id == 3
        @course_name      = Course.find(params[:course_id]).name
        @curriculum_units = CurriculumUnit.where(name: @course_name).order(:name)
      else
        @curriculum_units = CurriculumUnit.joins(:offers).where(curriculum_unit_type_id: @type.id).order(:name)
        @curriculum_units = @curriculum_units.where(offers: {course_id: params[:course_id]}) unless params[:course_id].blank?
      end

      render json: { html: render_to_string(partial: 'select_curriculum_unit.html', locals: { curriculum_units: @curriculum_units.uniq! }) }
    else # list
      authorize! :index, CurriculumUnit
      if not(params[:curriculum_unit_id].blank?)
        @curriculum_units = CurriculumUnit.where(id: params[:curriculum_unit_id]).paginate(page: params[:page])
      else
        allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "curriculum_units")
        @curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).paginate(page: params[:page])
      end
      respond_to do |format|
        format.html {render partial: 'curriculum_units/index'}
        format.js
      end
    end
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  # Mobilis
  # GET /curriculum_units/list.json
  def list
    respond_to do |format|
      format.json { render json: @curriculum_units }
      format.xml { render xml: @curriculum_units }
    end
  end

  # Mobilis
  # GET /curriculum_units/:curriculum_unit_id/groups/mobilis_list.json
  def mobilis_list
    respond_to do |format|
      format.json { render json: { curriculum_units: @curriculum_units } }
      format.xml { render xml: @curriculum_units }
    end
  end

  # GET /curriculum_units/new
  def new
    @curriculum_unit = CurriculumUnit.new(curriculum_unit_type_id: params[:type_id])
  end

  # POST /curriculum_units
  def create
    authorize! :create, CurriculumUnit

    @curriculum_unit = CurriculumUnit.new(curriculum_unit_params.merge!({user_id: current_user.id}))

    if @curriculum_unit.save
      render json: {success: true, notice: t('curriculum_units.success.created'), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
    else
      render :new
    end

  rescue => error
    request.format = :json
    raise error.class
  end

  # GET /curriculum_units/1/edit
  def edit
  end

  # PUT /curriculum_units/1
  def update
    if @curriculum_unit.update_attributes(curriculum_unit_params)
      render json: {success: true, notice: t('curriculum_units.success.updated'), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    uc_ids = params[:id].split(",")
    authorize! :destroy, CurriculumUnit, on: AllocationTag.where(curriculum_unit_id: uc_ids).pluck(:id)

    @curriculum_units = CurriculumUnit.where(id: uc_ids)
    if @curriculum_units.destroy_all.map(&:destroyed?).include?(false)
      render json: {success: false, alert: t('curriculum_units.error.deleted')}, status: :unprocessable_entity
    else
      render json: {success: true, notice: t('curriculum_units.success.deleted')}
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # information about UC from a offer from the group selected
  def informations
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]
    @offer = Offer.where(id: RelatedTaggable.where(group_at_id: @allocation_tags_ids).pluck(:offer_id).compact).first
  end

  def participants
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]
    @participants = AllocationTag.get_participants(@allocation_tags_ids, {students: true})
  end

  private

    def curriculum_unit_params
      params.require(:curriculum_unit).permit(:code, :name, :curriculum_unit_type_id, :resume, :syllabus, :passing_grade, :objectives, :prerequisites, :credits, :working_hours)
    end

    def curriculum_data
      @curriculum_unit = Offer.find(active_tab[:url][:id]).curriculum_unit
      @allocation_tag_id = active_tab[:url][:allocation_tag_id]
      @allocation_tags_ids = RelatedTaggable.related({group_at_id: @allocation_tag_id})
      @responsible = AllocationTag.get_participants(@allocation_tags_ids, {responsibles: true})
    end

    def list_portlet_discussion_posts(allocation_tags)
      Post.joins(:academic_allocation)
        .where(academic_allocations: {allocation_tag_id: allocation_tags})
        .select(%{substring("content" from 0 for 255) AS content}).select('*')
        .order("updated_at DESC").limit(Rails.application.config.items_per_page.to_i)
    end

    def ucs_for_list
      @curriculum_units = CurriculumUnit.all_by_user(current_user).collect {|uc| {id: uc.id, code: uc.code, name: uc.name}}

      if params.include?(:search)
        @curriculum_units = @curriculum_units.select {|uc| uc[:code].downcase.include?(params[:search].downcase) or uc[:name].downcase.include?(params[:search].downcase)}
      end
    end

end

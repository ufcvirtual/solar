class CurriculumUnitsController < ApplicationController
  include MessagesHelper

  layout false, only: [:new, :edit, :create]

  before_filter :prepare_for_group_selection, only: [:home, :participants, :informations]
  before_filter :curriculum_data, only: [:home, :informations, :participants]

  authorize_resource only: [:new]
  load_and_authorize_resource only: [:edit, :update]

  def home
    allocation_tags = @allocation_tags.map(&:id)
    authorize! :show, CurriculumUnit, on: allocation_tags, read: true

    @messages         = Message.user_inbox(current_user.id, @allocation_tag_id, only_unread = true)
    @lessons_modules  = LessonModule.to_select(allocation_tags, current_user)
    @discussion_posts = list_portlet_discussion_posts(allocation_tags.join(', '))

    schedules_events  = Agenda.events(allocation_tags)
    @scheduled_events = schedules_events.collect { |schedule_event|
      schedule_end_date = schedule_event['end_date'].nil? ? "" : schedule_event['end_date'].to_date
      [schedule_event['start_date'].to_date, schedule_end_date]
    }.flatten.uniq
  end

  def index
    @type = CurriculumUnitType.find(params[:type_id])
    @curriculum_units = []

    if params[:combobox]
      if @type.id == 3
        @course_name = Course.find(params[:course_id]).name
        @curriculum_units = CurriculumUnit.where(name: @course_name)
                                           .order(:name)
      else
        @curriculum_units = CurriculumUnit.joins(:offers).where(curriculum_unit_type_id: @type.id).where(offers: {course_id: params[:course_id]}).order(:name) if not(params[:course_id].blank?)
      end

      render json: { html: render_to_string(partial: 'select_curriculum_unit.html', locals: { curriculum_units: @curriculum_units.uniq! }) }
    else # list
      authorize! :index, CurriculumUnit
      if not(params[:curriculum_unit_id].blank?)
        @curriculum_units = CurriculumUnit.where(id: params[:curriculum_unit_id]).paginate(page: params[:page])
      else
        allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "curriculum_units")
        @curriculum_units   = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).paginate(page: params[:page])
      end
      respond_to do |format|
        format.html {render partial: 'curriculum_units/index'}
        format.js
      end
    end
  rescue => error
    raise "#{error}"
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  # Mobilis
  # GET /curriculum_units/list.json
  def list
    @curriculum_units = CurriculumUnit.all_by_user(current_user).collect {|uc| {id: uc.id, code: uc.code, name: uc.name}}

    if params.include?(:search)
      @curriculum_units = @curriculum_units.select {|uc| uc[:code].downcase.include?(params[:search].downcase) or uc[:name].downcase.include?(params[:search].downcase)}
    end

    respond_to do |format|
      format.json { render json: @curriculum_units }
      format.xml { render xml: @curriculum_units }
    end
  end

  # Mobilis
  # GET /curriculum_units/:curriculum_unit_id/groups/mobilis_list.json
  def mobilis_list
    @curriculum_units = CurriculumUnit.all_by_user(current_user).collect {|uc| {id: uc.id, code: uc.code, name: uc.name}}
    
    if params.include?(:search)
      @curriculum_units = @curriculum_units.select {|uc| uc[:code].downcase.include?(params[:search].downcase) or uc[:name].downcase.include?(params[:search].downcase)}
    end

    respond_to do |format|
      format.json { render json: { curriculum_units: @curriculum_units } }
      format.xml { render xml: @curriculum_units }
    end
  end

  # GET /curriculum_units/new
  # GET /curriculum_units/new.json
  def new
    @curriculum_unit = CurriculumUnit.new(curriculum_unit_type_id: params[:type_id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @curriculum_unit }
    end
  end

  # POST /curriculum_units
  # POST /curriculum_units.json
  def create
    params[:curriculum_unit].delete('code') if params[:curriculum_unit][:code] == ''
    params[:curriculum_unit].delete('prerequisites') if params[:curriculum_unit][:prerequisites] == ''
    params[:curriculum_unit][:user_id] = current_user.id

    @curriculum_unit = CurriculumUnit.new(params[:curriculum_unit])
    course = Course.new name: @curriculum_unit.name, code: @curriculum_unit.code if @curriculum_unit.curriculum_unit_type_id == 3

    authorize! :create, CurriculumUnit

    ActiveRecord::Base.transaction do
      @curriculum_unit.save!
      if @curriculum_unit.curriculum_unit_type_id == 3
        course.user_id = @curriculum_unit.user_id
        course.save!
      end
    end

    render json: {success: true, notice: t(:created, scope: [:curriculum_units, :success]), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
  rescue => error
    # if curso livre, add course errors to curriculum_unit
    (errors_keys = course.errors.keys).each{|key| @curriculum_unit.errors.add(key, course.errors.messages[key].flatten.first) } if @curriculum_unit.curriculum_unit_type_id == 3 and not(course.valid?)
    render :new
  end

  # GET /curriculum_units/1/edit
  def edit
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @curriculum_unit }
    end
  end

  # PUT /curriculum_units/1
  # PUT /curriculum_units/1.json
  def update
    params[:curriculum_unit].delete(:code) unless params[:curriculum_unit][:code].present?
    course = Course.find_by_name(@curriculum_unit.name)
    if @curriculum_unit.update_attributes(params[:curriculum_unit])
      course.update_attributes name: @curriculum_unit.name, code: @curriculum_unit.code if @curriculum_unit.curriculum_unit_type_id == 3 and (not course.nil?)
      render json: {success: true, notice: t(:updated, scope: [:curriculum_units, :success]), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
    else
      render :edit, layout: false
    end
  end

  def destroy
    @curriculum_unit = CurriculumUnit.where(id: params[:id].split(","))
    authorize! :destroy, CurriculumUnit, on: [@curriculum_unit.map(&:allocation_tag).map(&:id).compact.uniq]

    CurriculumUnit.transaction do
      begin
        @curriculum_unit.each do |curriculum_unit|
          raise "erro" unless curriculum_unit.destroy
        end
        render json: {success: true, notice: t(:deleted, scope: [:curriculum_units, :success])}
      rescue
        render json: {success: false, alert: t(:deleted, scope: [:curriculum_units, :error])}, status: :unprocessable_entity
      end
    end
  end

  # information about UC from a offer from the group selected
  def informations
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]

    @offer = @allocation_tags.select {|at| not(at.offer_id.nil?)}.first.try(:offer)
  end

  def participants
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]

    allocation_tags = @allocation_tags.map(&:id).join(",")
    @participants = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(allocation_tags, Profile_Type_Student)
  end

  private

    def curriculum_data
      @curriculum_unit   = Offer.find(active_tab[:url][:id]).curriculum_unit
      @allocation_tag_id = active_tab[:url][:allocation_tag_id]
      @allocation_tags = AllocationTag.find(@allocation_tag_id).related(objects: true)

      at_ids = @allocation_tags.map(&:id).join(",")

      @responsible = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(at_ids, Profile_Type_Class_Responsible)
    end

    def list_portlet_discussion_posts(allocation_tags)
      Post.joins(:academic_allocation)
        .where(academic_allocations: {allocation_tag_id: allocation_tags})
        .select(%{substring("content" from 0 for 255) AS content}).select('*')
        .order("updated_at DESC").limit(Rails.application.config.items_per_page.to_i)
    end

end

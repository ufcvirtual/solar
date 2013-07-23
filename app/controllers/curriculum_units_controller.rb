include MessagesHelper

class CurriculumUnitsController < ApplicationController

  layout false, :only => [:new, :edit, :show, :create, :update]

  before_filter :prepare_for_group_selection, :only => [:home, :participants, :informations]
  before_filter :curriculum_data, :only => [:home, :informations, :curriculum_data, :participants]

  authorize_resource :only => [:index, :show, :new]
  load_and_authorize_resource :only => [:destroy, :edit]

  # GET /curriculum_units
  # GET /curriculum_units.json
  # def index
  #   @curriculum_units = CurriculumUnit.joins(:allocations).where(:allocations => { :profile_id => Curriculum_Unit_Initial_Profile, :user_id => current_user.id } )

  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.json { render json: @curriculum_units }
  #   end
  # end

  # Acadêmico
  def index
    @type = params[:type]
    if (not params[:curriculum_unit_id].blank?) # recebe o id do curso pelo nome
      @curriculum_units = [CurriculumUnit.find(params[:curriculum_unit_id])]
    else
      @curriculum_units = CurriculumUnit.find_all_by_curriculum_unit_type_id(params[:type])
    end
    render partial: 'curriculum_units/index'
  end


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

  # GET /curriculum_units/1
  # GET /curriculum_units/1.json
  def show
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @curriculum_unit }
    end
  end

  def home
    allocation_tags   = AllocationTag.find(@allocation_tag_id).related({all: true, objects: true}).map(&:id)
    @messages         = Message.user_inbox(current_user.id, only_unread = true)
    @lessons          = Lesson.to_open(allocation_tags.join(', '))
    @discussion_posts = list_portlet_discussion_posts(allocation_tags.join(', '))

    schedules_events  = Schedule.events(allocation_tags)
    @scheduled_events = schedules_events.collect { |schedule_event|
      schedule_end_date = schedule_event['end_date'].nil? ? "" : schedule_event['end_date'].to_date
      [schedule_event['start_date'].to_date, schedule_end_date]
    }.flatten.uniq
  end

  def destroy
    @curriculum_unit = CurriculumUnit.find(params[:id])
    #authorize! :destroy, CurriculumUnit

    if @curriculum_unit.destroy
      render json: {success: true, notice: t(:deleted, scope: [:semesters, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:semesters, :error])}, status: :unprocessable_entity
    end
  end

  # GET /curriculum_units/new
  # GET /curriculum_units/new.json
  def new
    @curriculum_unit = CurriculumUnit.new(curriculum_unit_type_id: params[:type])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @curriculum_unit }
    end
  end

  # GET /curriculum_units/1/edit
  def edit
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

    authorize! :create, CurriculumUnit

    if @curriculum_unit.save
      render json: {success: true, notice: t(:created, scope: [:semesters, :success])}
    else
      render :new
    end
  end

  # PUT /curriculum_units/1
  # PUT /curriculum_units/1.json
  def update
    @curriculum_unit = CurriculumUnit.find(params[:id])
    params[:curriculum_unit].delete(:code) unless params[:curriculum_unit][:code].present?

    if @curriculum_unit.update_attributes(params[:curriculum_unit])
      render json: {success: true, notice: t(:updated, scope: [:semesters, :success])}
    else
      render :edit
    end

  end

  def informations
    allocation_tags   = AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])
    allocation_offer  = AllocationTag.where("id IN (#{allocation_tags.join(', ')}) AND offer_id IS NOT NULL").first
    @offer            = allocation_offer.offer unless allocation_offer.nil?
  end

  def participants
    @student_profile = Profile.student_profile # retorna perfil em que se pede matricula (~aluno)
    allocation_tags  = AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])
    @participants    = CurriculumUnit.class_participants_by_allocations_tags_and_is_not_profile_type(allocation_tags.join(','), Profile_Type_Class_Responsible)
  end

  private

    def curriculum_data
      authorize! :show, @curriculum_unit = CurriculumUnit.find(active_tab[:url][:id])

      @allocation_tag_id = active_tab[:url][:allocation_tag_id]
      @responsible = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(AllocationTag.find_related_ids(@allocation_tag_id).join(','),
        Profile_Type_Class_Responsible)
    end

    def list_portlet_discussion_posts(allocation_tags)
      Post.joins(:discussion).where(discussions: {allocation_tag_id: allocation_tags}).select(%{substring("content" from 0 for 255) AS content}).select('*').order("updated_at DESC").limit(Rails.application.config.items_per_page.to_i)
    end

end

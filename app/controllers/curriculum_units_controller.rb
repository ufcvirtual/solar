include MessagesHelper

class CurriculumUnitsController < ApplicationController

  layout false, :only => [:new, :edit, :show, :create, :update]

  before_filter :prepare_for_group_selection, :only => [:home, :participants, :informations]
  before_filter :curriculum_data, :only => [:home, :informations, :curriculum_data]

  authorize_resource :only => [:index, :show, :new]
  load_and_authorize_resource :only => [:destroy, :edit]

  # GET /curriculum_units
  # GET /curriculum_units.json
  def index
    @curriculum_units = CurriculumUnit.joins(:allocations).where(:allocations => { :profile_id => Curriculum_Unit_Initial_Profile, :user_id => current_user.id } )

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @curriculum_units }
    end
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
    allocation_tags   = AllocationTag.find(@allocation_tag_id).related({all: true, objects: true})
    group             = allocation_tags.select { |at| not(at.group_id.nil?) }
    offer             = allocation_tags.select { |at| not(at.offer_id.nil?) }.first.offer
    @messages         = return_messages(current_user.id, 'portlet', get_label_name(group, offer, @curriculum_unit))

    allocation_tags   = allocation_tags.map(&:id)
    @lessons          = Lesson.to_open(allocation_tags.join(', '))
    @discussion_posts = list_portlet_discussion_posts(allocation_tags.join(', '))

    schedules_events  = Schedule.events(allocation_tags)
    @scheduled_events = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'].to_date.to_s(:db), schedule_event['end_date'].to_date.to_s(:db)]
    }.flatten.uniq
  end

  # DELETE /curriculum_units/1
  # DELETE /curriculum_units/1.json
  def destroy
    respond_to do |format|
      if @curriculum_unit.destroy
        format.html { redirect_to curriculum_units_url, notice: t(:successfully_deleted, :register => @curriculum_unit.name) }
        format.json { head :ok }
      else
        format.html { redirect_to curriculum_units_url, alert: t(:cant_delete, :register => @curriculum_unit.name) }
        format.json { render json: @curriculum_unit.errors }
      end
    end
  end

  # GET /curriculum_units/new
  # GET /curriculum_units/new.json
  def new
    @curriculum_unit = CurriculumUnit.new

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

    begin
      authorize! :create, CurriculumUnit
      raise "error" unless @curriculum_unit.save

      @curriculum_units = CurriculumUnit.joins(:allocations).where(:allocations => { :profile_id => Curriculum_Unit_Initial_Profile, :user_id => current_user.id } )
      respond_to do |format|
        format.html { render :index, :status => 200 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html { render :new, :status => ((error.message == "error") ? 200 : 500 ) }
      end
    end

  end

  # PUT /curriculum_units/1
  # PUT /curriculum_units/1.json
  def update
    @curriculum_unit = CurriculumUnit.find(params[:id])
    params[:curriculum_unit].delete :code if params[:code].blank? # o parâmetro deve não existir para que possa ser aceito como vazio

    begin
      authorize! :update, @curriculum_unit
      raise "error" unless @curriculum_unit.update_attributes(params[:curriculum_unit])

      @curriculum_units = CurriculumUnit.joins(:allocations).where(:allocations => { :profile_id => Curriculum_Unit_Initial_Profile, :user_id => current_user.id } )
      respond_to do |format|
        format.html{ render :index, :status => 200 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html { render :edit, :status => ((error.message == "error") ? 200 : 500 ) }
      end
    end

  end

  def informations
    allocation_tags   = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    allocation_offer  = AllocationTag.where("id IN (#{allocation_tags.join(', ')}) AND offer_id IS NOT NULL").first
    @offer            = allocation_offer.offer unless allocation_offer.nil?
  end

  def participants
    @student_profile = Profile.student_profile # retorna perfil em que se pede matricula (~aluno)
    allocation_tags  = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    @participants    = CurriculumUnit.class_participants_by_allocations_tags_and_is_not_profile_type(allocation_tags.join(','), Profile_Type_Class_Responsible)
  end

  private

    def curriculum_data
      authorize! :show, @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id'])

      @allocation_tag_id = active_tab[:url]['allocation_tag_id']
      @responsible = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(AllocationTag.find_related_ids(@allocation_tag_id).join(','),
        Profile_Type_Class_Responsible)
    end

    def list_portlet_discussion_posts(allocation_tags)
      Post.joins(:discussion).where(discussions: {allocation_tag_id: allocation_tags}).select(%{substring("content" from 0 for 255) AS content}).select('*').order("updated_at DESC").limit(Rails.application.config.items_per_page.to_i)
    end

end

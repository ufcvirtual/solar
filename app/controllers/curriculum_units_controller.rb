include CurriculumUnitsHelper
include MessagesHelper

class CurriculumUnitsController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:home, :participants, :informations]

  #  load_and_authorize_resource

  # GET /curriculum_units
  # GET /curriculum_units.json
  def index
    @curriculum_units = CurriculumUnit.find_default_by_user_id(current_user.id, true)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @curriculum_units }
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
    curriculum_data

    allocation_tags = AllocationTag.find_related_ids(@allocation_tag_id).join(', ');

    # relacionado diretamente com a allocation_tag
    group = AllocationTag.where("id IN (#{allocation_tags}) AND group_id IS NOT NULL").first.group

    # offer
    al_offer = AllocationTag.where("id IN (#{allocation_tags}) AND offer_id IS NOT NULL").first
    offer = al_offer.nil? ? nil : al_offer.offer

    # curriculum_unit
    al_c_unit = AllocationTag.where("id IN (#{allocation_tags}) AND curriculum_unit_id IS NOT NULL").first
    curriculum_unit = al_c_unit.nil? ? CurriculumUnit.find(active_tab[:url]['id']) : al_c_unit.curriculum_unit

    message_tag = get_label_name(group, offer, curriculum_unit)

    # retorna aulas, posts nos foruns e mensagens relacionados a UC mais atuais
    @lessons = Lesson.to_open(@allocation_tag_id)
    @discussion_posts = list_portlet_discussion_posts(allocation_tags)
    @messages = return_messages(current_user.id, 'portlet', message_tag)

    # destacando dias que possuem eventos
    schedules_events = Schedule.all_by_allocation_tags(allocation_tags)
    @scheduled_events = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'].to_date.to_s(), schedule_event['end_date'].to_date.to_s()]
    }.flatten.uniq
  end

  # DELETE /curriculum_units/1
  # DELETE /curriculum_units/1.json
  def destroy
    @curriculum_unit = CurriculumUnit.find(params[:id])
    @curriculum_unit.destroy

    respond_to do |format|
      format.html { redirect_to curriculum_units_url }
      format.json { head :no_content }
      format.xml { head :ok }
    end
  end

  # GET /curriculum_units/new
  # GET /curriculum_units/new.json
  def new
    @curriculum_unit = CurriculumUnit.new

    respond_to do |format|
      format.html { render layout: false } # new.html.erb
      format.json { render json: @curriculum_unit }
    end
  end

  # GET /curriculum_units/1/edit
  def edit
    @curriculum_unit = CurriculumUnit.find(params[:id])
  end

  # POST /curriculum_units
  # POST /curriculum_units.json
  def create
    params[:curriculum_unit].delete('code') if params[:curriculum_unit][:code] == ''
    params[:curriculum_unit].delete('prerequisites') if params[:curriculum_unit][:prerequisites] == ''

    @curriculum_unit = CurriculumUnit.new(params[:curriculum_unit])

    respond_to do |format|
      if @curriculum_unit.save
        format.html { redirect_to @curriculum_unit, notice: 'Curriculum unit was successfully created.' }
        format.json { render json: @curriculum_unit, status: :created, location: @curriculum_unit }
      else
        format.html { render action: "new" }
        format.json { render json: @curriculum_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /curriculum_units/1
  # PUT /curriculum_units/1.json
  def update
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      if @curriculum_unit.update_attributes(params[:curriculum_unit])
        format.html { redirect_to @curriculum_unit, notice: 'Curriculum unit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @curriculum_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  def informations
    curriculum_data

    allocation_tags = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    allocation_offer = AllocationTag.where("id IN (#{allocation_tags.join(', ')}) AND offer_id IS NOT NULL").first
    @offer = allocation_offer.offer unless allocation_offer.nil?
  end

  def participants
    curriculum_data

    @student_profile = student_profile # retorna perfil em que se pede matricula (~aluno)
    allocation_tags = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    @participants = CurriculumUnit.class_participants_by_allocations_tags_and_is_not_profile_type(allocation_tags.join(','), Profile_Type_Class_Responsible)
  end

  private

  def curriculum_data
    @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id'])
    @allocation_tag_id = active_tab[:url]['allocation_tag_id']
    @responsible = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(AllocationTag.find_related_ids(@allocation_tag_id).join(','),
      Profile_Type_Class_Responsible)
  end

  def list_portlet_discussion_posts(allocation_tags)
    discussions = Discussion.where(:allocation_tag_id => allocation_tags).map { |d| d.id }.join(',')
    return [] if discussions.empty? 
    Post.recent_by_discussions(discussions, Rails.application.config.items_per_page.to_i)
  end

end

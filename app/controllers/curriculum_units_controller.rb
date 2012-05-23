include CurriculumUnitsHelper
include DiscussionPostsHelper
include MessagesHelper

class CurriculumUnitsController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:show, :participants, :informations]

  #  load_and_authorize_resource

  def index
    @curriculum_units = CurriculumUnit.find_default_by_user_id(current_user.id)

    respond_to do |format|
      # format.html
      format.xml  { render :xml => @curriculum_units }
      format.json  { render :json => @curriculum_units }
    end
  end

  def show
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

  def destroy
    @curriculum_unit.destroy

    respond_to do |format|
      format.html
      format.xml { head :ok }
    end
  end
  
  def new
    @curriculum_unit = CurriculumUnit.new
    respond_to do |format|
      format.html  # new.html.erb
      format.json  { render :json => @curriculum_unit }
    end
  end
  
  def create
    params[:curriculum_unit].delete('code') if params[:curriculum_unit][:code] == ''

    @curriculum_unit = CurriculumUnit.new(params[:curriculum_unit])
    respond_to do |format| 
      if @curriculum_unit.save :validate => 'UC was successfully created.'
        format.html { redirect_to(@curriculum_unit) } 
        format.xml { render :xml => @curriculum_unit, :status => :created, :location => @curriculum_unit } 
      else format.html { render :action => "new" } 
        format.xml { render :xml => @curriculum_unit.errors, :status => :unprocessable_entity } 
      end 
    end 
  end

  def informations
    curriculum_data

    allocations = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    allocation_offer = AllocationTag.where("id IN (#{allocations.join(', ')}) AND offer_id IS NOT NULL").first
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

end

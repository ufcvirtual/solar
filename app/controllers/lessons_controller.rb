class LessonsController < ApplicationController

  include EditionHelper

  before_filter :prepare_for_group_selection, :only => [:index]
  before_filter :curriculum_data

  load_and_authorize_resource :except => [:index]

  def show
    render :layout => 'lesson_frame'
  end

  def show_header
    @lessons = lessons_to_open
    render :layout => 'lesson'
  end

  def show_content
    render :layout => 'lesson'
  end

  def index
    authorize! :index, Lesson
    @lessons              = lessons_to_open(params[:allocation_tags_ids])
    @group_and_offer_info = group_and_offer_info(params[:group_id], params[:offer_id]) if params[:allocation_tags_ids]

    render :layout => false if params[:allocation_tags_ids]
  end

  # listagem do cadastro de aulas  
  def list
  end

  private

    def curriculum_data
      @curriculum_unit = CurriculumUnit.find(params[:curriculum_unit_id] || active_tab[:url]['id'])
    end

    def lessons_to_open(allocation_tags_ids = nil)
      allocation_tags_ids = allocation_tags_ids || AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
      Lesson.to_open(allocation_tags_ids.join(", "))
    end
end

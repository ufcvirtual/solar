class LessonsController < ApplicationController

  include EditionHelper

  before_filter :prepare_for_group_selection, :only => [:index]
  before_filter :curriculum_data, :except => [:list]

  load_and_authorize_resource :except => [:index, :list]

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
    # verifica permissao de acessar aulas cadastradas nas allocation tags passadas
    #authorize! :list, Lesson, :on => [params[:allocation_tag_id].to_i]

    @allocation_tags  = (params.include?('allocation_tag_id')) ? params[:allocation_tag_id] : 0

    @lesson_modules = LessonModule.find(:all,
      :conditions => ["allocation_tag_id IN (#{@allocation_tags}) "],
      :order => ["lesson_modules.order"]) 

    respond_to do |format|
      flash[:notice] = t(:allocated, :scope => [:allocations, :success]) if params.include?(:notice_allocated)
      flash[:alert]  = t(:not_allocated, :scope => [:allocations, :error]) if params.include?(:alert_allocated)
      format.html 
      format.json { render json: @allocations }
    end
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

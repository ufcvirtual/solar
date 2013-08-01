class EditionsController < ApplicationController

  # authorize_resource :only => [:index]

  def index
  end

  def items
    if params[:groups_id].blank?
      @allocation_tags_ids = [Offer.where(semester_id: params[:semester_id], curriculum_unit_id: params[:curriculum_unit_id], course_id: params[:course_id]).first.allocation_tag.id]
      @offer = true
    else
      @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id]).map(&:id)
      @group = true
    end

    # raise "list discussion ==> #{(can? :list, Discussion, :on => @allocation_tags_ids)}"

    # @allocation_tags_ids = params[:allocation_tags_ids] || []
    # @selected_course     = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).course}.include?(true)
    # @selected_offer      = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).offer}.include?(true)
    # @selected_group      = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).group}.include?(true)
    render :partial => "items"
  end

  # GET /editions/academic
  def academic
    @types = CurriculumUnitType.all
    @type  = params[:type_id]
  end

  def courses
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = Course.all
  end

  def curriculum_units
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
  end

  def semesters
    @periods = [[t(:actives, scope: [:editions, :semesters]), "active"], [t(:all, scope: [:editions, :semesters]), "all"]]
    @periods += Schedule.joins(:semester_periods).map {|p| [p.start_date.year, p.end_date.year] }.flatten.uniq.sort! {|x,y| y <=> x} # desc

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
    @courses = Course.all
    @semesters = Semester.all_by_period({period: params[:period]}) # semestres do período informado ou ativos
  end

  def groups
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = Course.joins(offers: [:groups, :curriculum_unit]).where(curriculum_units: {curriculum_unit_type_id: @type.id}).uniq
  end

  def content
    @types = CurriculumUnitType.all
  end

end

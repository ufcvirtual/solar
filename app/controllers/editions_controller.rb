class EditionsController < ApplicationController

  def items
    if params[:groups_id].blank?
      @allocation_tags_ids = [Offer.where(semester_id: params[:semester_id], curriculum_unit_id: params[:curriculum_unit_id], course_id: params[:course_id]).first.allocation_tag.id]
      @offer = true
    else
      @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id]).map(&:id)
      @group = true
    end

    render :partial => "items"
  end

  # GET /editions/academic
  def academic
    authorize! :academic, Edition
    @types = CurriculumUnitType.all
    @type  = params[:type_id]
  end

  def courses
    authorize! :courses, Edition
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = Course.all
  end

  def curriculum_units
    authorize! :curriculum_units, Edition
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
  end

  def semesters
    authorize! :semesters, Edition
    @periods = [[t(:actives, scope: [:editions, :semesters]), "active"], [t(:all, scope: [:editions, :semesters]), "all"]]
    @periods += Schedule.joins(:semester_periods).map {|p| [p.start_date.year, p.end_date.year] }.flatten.uniq.sort! {|x,y| y <=> x} # desc

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
    @courses = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
    @semesters = Semester.all_by_period({period: params[:period]}) # semestres do período informado ou ativos
  end

  def groups
    authorize! :groups, Edition
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
  end

  # GET /editions/content
  def content
    authorize! :content, Edition
    @types = CurriculumUnitType.all
  end

end

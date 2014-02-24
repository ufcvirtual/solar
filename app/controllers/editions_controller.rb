class EditionsController < ApplicationController

  def items
    @all_groups_allocation_tags = []

    if params[:groups_id].blank?
      if params.include?(:semester_id) and (not params[:semester_id] == "")
        @allocation_tags_ids = [Offer.where(semester_id: params[:semester_id], curriculum_unit_id: params[:curriculum_unit_id], course_id: params[:course_id]).first.allocation_tag.id]
        @selected = "OFFER"
      elsif params.include?(:curriculum_unit_id) and (not params[:curriculum_unit_id] == "")
        @allocation_tags_ids = [CurriculumUnit.find(params[:curriculum_unit_id]).allocation_tag.id]
        @selected = "CURRICULUM_UNIT"
      elsif params.include?(:course_id) and (not params[:course_id] == "")
        @allocation_tags_ids = [Course.find(params[:course_id]).allocation_tag.id]
        @selected = "COURSE"
      end
    else
      @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id]).map(&:id)
      @selected = "GROUP"
      @all_groups_ids = params[:all_groups_ids].split(" ") unless params[:all_groups_ids].nil? # todas as turmas existentes no filtro
    end

    render partial: "items"
  end

  # GET /editions/academic
  def academic
    authorize! :academic, Edition

    @types = CurriculumUnitType.all
    @type = params[:type_id]
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

  def edx_courses
    edx_urls = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]['urls']

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    url = URI.parse(edx_urls["list_available_courses"])
    res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    @edx_courses = JSON.parse(res.body)["objects"]
    render layout: false if params.include?(:layout)
  end    

  # GET /editions/content
  def content
    authorize! :content, Edition
    @types = CurriculumUnitType.all
  end

end

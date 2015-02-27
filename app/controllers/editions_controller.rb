include EdxHelper

class EditionsController < ApplicationController

  def items
    allocation_tags = AllocationTag.get_by_params(params)
    @allocation_tags_ids, @selected, @offer_id = allocation_tags.values_at(:allocation_tags, :selected, :offer_id)
    authorize! :content, Edition, on: @allocation_tags_ids
    @user_profiles       = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)
    @allocation_tags_ids = @allocation_tags_ids.join(" ")

    render partial: "items"
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  # GET /editions/academic
  def academic
    authorize! :academic, Edition
    @types = ((not(EDX.nil?) and EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
    @type  = params[:type_id]
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def courses
    authorize! :courses, Edition

    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "courses")
    @search_courses = Course.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
    @courses = @search_courses.paginate(page: params[:page])
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def curriculum_units
    authorize! :curriculum_units, Edition

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "curriculum_units")
    @search_curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
    @curriculum_units   = @search_curriculum_units.paginate(page: params[:page])
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def semesters
    authorize! :semesters, Edition
    @periods  = [[t(:actives, scope: [:editions, :semesters]), "active"], [t(:all, scope: [:editions, :semesters]), "all"]]
    @periods += Schedule.joins(:semester_periods).map {|p| [p.start_date.year, p.end_date.year] }.flatten.uniq.sort! {|x,y| y <=> x} # desc

    @allocation_tags_ids = AllocationTag.where(id: current_user.allocation_tags_ids_with_access_on([:update, :destroy], "offers")).map{|at| at.related}.flatten.uniq
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])

    @curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids})
    @courses   = ( @type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : @courses = Course.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}) )
    @semesters = Semester.all_by_period({period: params[:period], user_id: current_user.id, type_id: @type.id}) # semestres do período informado ou ativos

    @allocation_tags_ids = @allocation_tags_ids.join(" ")
  rescue => error
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def groups
    authorize! :groups, Edition
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
    @curriculum_units = (@type.id == 3 ? [] : CurriculumUnit.where(curriculum_unit_type_id: @type))
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edx_courses
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])

    verify_or_create_user_in_edx(current_user)

    url = URI.parse(EDX_URLS["verify_user"].gsub(":username", current_user.username)+"instructor/")
    res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    uri_courses = JSON.parse(res.body) #pega endereço dos cursos
    courses_created_by_current_user = "[]"
      unless uri_courses.empty?
        if uri_courses.class == Hash and uri_courses.has_key?("error_message")
          raise uri_courses["error_message"]
        else
          courses_created_by_current_user = ""
          for uri_course in uri_courses do
            url = URI.parse(EDX_URLS["information_course"].gsub(":resource_uri", uri_course))
            res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
            courses_created_by_current_user  << res.body.chop! << ", \"resource_uri\":  \"#{uri_course}\""<<"}, "
          end

          courses_created_by_current_user = courses_created_by_current_user.chop
          courses_created_by_current_user = "[" + courses_created_by_current_user.chop! + "]"
        end
      end
      @edx_courses = JSON.parse(courses_created_by_current_user)

    render layout: false if params.include?(:layout)
  rescue => error
    redirect_to :back, alert: t("edx.errors.cant_connect")
  end

  # GET /editions/content
  def content
    authorize! :content, Edition
    @types = ((not(EDX.nil?) and EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end

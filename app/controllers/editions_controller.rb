include EdxHelper  

class EditionsController < ApplicationController

  EDX = YAML::load(File.open("config/edx.yml"))[Rails.env.to_s]

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
    @types = ((File.exist?("config/edx.yml") and EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
    @type  = params[:type_id]
  end

  def courses
    authorize! :courses, Edition

    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = Course.all
  end

  def curriculum_units
    authorize! :curriculum_units, Edition

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
  end

  def semesters
    authorize! :semesters, Edition
    @periods  = [[t(:actives, scope: [:editions, :semesters]), "active"], [t(:all, scope: [:editions, :semesters]), "all"]]
    @periods += Schedule.joins(:semester_periods).map {|p| [p.start_date.year, p.end_date.year] }.flatten.uniq.sort! {|x,y| y <=> x} # desc

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @curriculum_units = @type.curriculum_units
    @courses   = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
    @semesters = Semester.all_by_period({period: params[:period]}) # semestres do período informado ou ativos
  end

  def groups
    authorize! :groups, Edition
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
  end

  def edx_courses
    edx_urls = EDX['urls']
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])

    create_user_solar_in_edx(current_user.username,current_user.name,current_user.email) 

    url = URI.parse(edx_urls["verify_user"].gsub(":username", current_user.username)+"instructor/")
    res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    uri_courses = JSON.parse(res.body) #pega endereço dos cursos
    courses_created_by_current_user = "[]" 
      unless uri_courses.empty?
        if uri_courses.class == Hash and uri_courses.has_key?("error_message")
          raise uri_courses["error_message"]
        else
          courses_created_by_current_user = ""
          for uri_course in uri_courses do
            url = URI.parse(edx_urls["information_course"].gsub(":resource_uri", uri_course))
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
    @types = ((File.exist?("config/edx.yml") and EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
  end

end

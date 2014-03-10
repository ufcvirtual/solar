class EdxCoursesController < ApplicationController

  layout false, except: [:index, :items]

  EDX = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]

  EDX_URLS = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]['urls']

  # listar cursos do usuario
  def my
    @courses = []

    if check_me(current_user.username)
      res = get_response(EDX_URLS["list_users_courses"].gsub(":username", current_user.username))
      uri_courses = JSON.parse(res.body) #pega endereço dos cursos
      @courses = convert_url_course_in_data_course(uri_courses)
    end   
  end

  # listar cursos disponíveis
  def available
    @available_courses, @my_courses = [], []

    res = get_response(EDX_URLS["list_available_courses"])
    if (params[:type].blank? or params[:type].to_i == 7) and params[:uc].blank? # (if no search is made or public courses are searched) and no uc is searched
      @available_courses = JSON.parse(res.body)["objects"]  # all available edx courses
      @my_courses        = my.map { |mc| mc['course_id'] } unless my.nil? # courses ids which user is enrolled
      @available_courses.select!{ |course| course if @my_courses.include?(course["course_id"])} if params[:status] == "enroll" # courses which user is enrolled if searched for enrolled courses
    end
  end

  # matricular
  def enroll
    create_user_solar_in_edx(current_user.username,current_user.name,current_user.email)
    
    course = {
    "course_resource_uri" => Base64.decode64(params[:course])
      }.to_json

    uri  = URI.parse(EDX_URLS["enroll_or_unenroll"].gsub(":username", current_user.username))
    http = Net::HTTP.new(uri.host,uri.port)
    req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = course
    res  = http.request(req)

    redirect_to enrollments_path
  end  

  #cancelar matricular
  def unenroll
    course = {
    "course_resource_uri" => Base64.decode64(params[:course])
      }.to_json

    uri  = URI.parse(EDX_URLS["enroll_or_unenroll"].gsub(":username", current_user.username))
    http = Net::HTTP.new(uri.host,uri.port)
    req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json' , 'X-HTTP-METHOD-OVERRIDE' => 'DELETE'})
    req.body = course
    res  = http.request(req)

    redirect_to enrollments_path
  end


  #Edição Conteúdo
  def items
    @uri_course = params[:edx_course_id]
    res = get_response(EDX_URLS["information_course"].gsub(":resource_uri", @uri_course))
    course = JSON.parse(res.body)
    @edit_course_url = course['course_absolute_url_studio']
    render partial: 'items'
  end  

  # GET /edx_courses/content
  def content
    @types = CurriculumUnitType.all
    res = get_response(EDX_URLS["verify_user"].gsub(":username", current_user.username)+"instructor/")
    uri_courses = JSON.parse(res.body) #pega endereço dos cursos
    @edx_courses = convert_url_course_in_data_course(uri_courses)
  end

  def allocate
    uri_course = Base64.decode64(params[:course])
    user_uri = "/solaredx/api/v1/#{params[:username]}/"
    user = User.find_by_username(params[:username])
    create_user_solar_in_edx(user.username,user.name,user.email)
    professor = {
      user_resource_uri: user_uri
    }.to_json
    uri = URI.parse(EDX_URLS["information_course"].gsub(":resource_uri", uri_course)+params[:profile]+"/")  
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = professor
    res = http.request(req)

    redirect_to(designates_edx_courses_path(params[:course])) if res.code == "201"
  end

  def deallocate
    uri_course = Base64.decode64(params[:course])
    user_uri = "/solaredx/api/v1/#{params[:username]}/"
    professor = {
    "user_resource_uri" => user_uri
      }.to_json
    uri = URI.parse(EDX_URLS["information_course"].gsub(":resource_uri", uri_course)+params[:profile]+"/")  
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json', 'X-HTTP-METHOD-OVERRIDE' => 'DELETE'})
    req.body = professor
    res = http.request(req)

    redirect_to(designates_edx_courses_path(params[:course]))  if res.code == "204"
  end

  def designates
    @uri_course, course_dec = params[:course], Base64.decode64(params[:course])

    instructor = get_response("#{EDX['host']}#{course_dec}instructor/")
    @instructors = JSON.parse(instructor.body)

    staff = get_response("#{EDX['host']}#{course_dec}staff/")
    @staffs = JSON.parse(staff.body)
  end

  # Método, chamado por ajax, para buscar usuários para alocação
  def search_users
    @uri_course = Base64.decode64(params[:course])
    text                 = URI.unescape(params[:user])
    @text_search         = text
    @users               = User.where("lower(name) ~ '#{text.downcase}'")
  end


  # Edição acadêmica
  def index
    if (not params[:edx_course_id].blank?)
      res = get_response(EDX["host"] + params[:edx_course_id])
      @edx_courses  = JSON.parse("[" + res.body + "]")
      @resource_uri = params[:edx_course_id]
    else
      res = get_response(EDX_URLS["verify_user"].gsub(":username", current_user.username)+"instructor/")
      uri_courses = JSON.parse(res.body) #pega endereço dos cursos
      @edx_courses = convert_url_course_in_data_course(uri_courses)
    end
    render partial: 'edx_courses/index' 
  end  

  def new
    @course = Course.new(params[:course])
    @courses_names = params[:courses_names]
  end

  def create
    create_user_solar_in_edx(current_user.username,current_user.name,current_user.email)
    @courses_names = params[:courses_names]

    begin
      @course = Course.new(params[:course])
      @course.edx_course, @course.courses_names = true, @courses_names
      @course.save! unless @course.valid?

      semester  = Date.today.year.to_s << (Date.today.month < 7 ? ".1" : ".2")
      code      = @course.name.slice(0..2).upcase
      course_id = [current_user.institution,code,semester].join("/")
      course    = {course_id: course_id , display_name: @course.name, course_creator_username: current_user.username}.to_json

      uri  = URI.parse(EDX_URLS["insert_course"])
      http = Net::HTTP.new(uri.host,uri.port)
      req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
      req.body = course
      res  = http.request(req) 

      render json: {success: true, notice: t(:created, scope: [:courses, :success]), url: academic_edx_courses_editions_path(7, layout: false)}
    rescue => error
      render :new, layout: false
    end
  end 

  def delete
    begin 
      course      = Base64.decode64(params[:course])
      data_course = {confirm: "true"}.to_json

      uri  = URI.parse(EDX["host"]+course)
      http = Net::HTTP.new(uri.host,uri.port)
      req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json' , 'X-HTTP-METHOD-OVERRIDE' => 'DELETE'})
      req.body = data_course
      res  = http.request(req) 

      render json: {success: true, notice: t(:deleted, scope: [:courses, :success]), url: academic_edx_courses_editions_path(7, layout: false)}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:courses, :error])}, status: :unprocessable_entity
    end
  end  

  def convert_url_course_in_data_course(uris)
    courses = "[]"
    unless uris.empty?
      courses = ""
      for uri in uris do
        res = get_response(EDX_URLS["information_course"].gsub(":resource_uri", uri))
        courses  << res.body.chop! << ", \"resource_uri\":  \"#{uri}\""<<"}, "
      end

      courses = courses.chop
      courses = "[" + courses.chop! + "]"
    end
    json_courses = JSON.parse(courses)
  end    

   
  private

    def get_response(url)
      url = URI.parse(url)
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    end

    # verificar usuario
    def check_me(username)
      url = URI.parse(EDX_URLS["verify_user"].gsub(":username", username))
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }

      begin
        res.value

        return true
      rescue
        return false
      end
    end

    def create_user_solar_in_edx(username,name,email)
      unless check_me(username)
        user = {username: username, name: name, email: email}.to_json
         
        uri  = URI.parse(EDX_URLS["insert_user"])
        http = Net::HTTP.new(uri.host,uri.port)

        req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = user
        res  = http.request(req)
      end  
    end  

end

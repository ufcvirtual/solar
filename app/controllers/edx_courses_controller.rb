class EdxCoursesController < ApplicationController

  layout false, except: :index

  EDX = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]

  EDX_URLS = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]['urls']

  # listar cursos do usuario
  def my
    @courses = []

    if check_me
      res = get_response(EDX_URLS["list_users_courses"].gsub(":username", current_user.username))
      uri_courses = JSON.parse(res.body) #pega endereço dos cursos
      my_courses = ""
      unless uri_courses.empty?
        for uri_course in uri_courses do
          res = get_response(EDX_URLS["information_course"].gsub(":resource_uri", uri_course))
          my_courses  << res.body << ","
        end

        my_courses = my_courses.chop
        my_courses = "[" + my_courses + "]"
        @courses = JSON.parse(my_courses)
      end
    end   
  end

  # listar cursos disponíveis
  def available
    @available_courses, @my_courses = [], []

    ## todos
    res = get_response(EDX_URLS["list_available_courses"])
    @available_courses = JSON.parse(res.body)["objects"]
    @my_courses = my.map { |mc| mc['course_id'] } unless my.nil?
 
  end


  # matricular
  def enroll
    create_user_solar_in_edx
    
    course = {
    "course_resource_uri" => Base64.decode64(params[:course])
      }.to_json

    uri = URI.parse(EDX_URLS["enroll_or_unenroll"].gsub(":username", current_user.username))
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = course
    res = http.request(req)

    redirect_to enrollments_path
  end  

  #cancelar matricular
  def unenroll
    course = {
    "course_resource_uri" => Base64.decode64(params[:course])
      }.to_json

    uri = URI.parse(EDX_URLS["enroll_or_unenroll"].gsub(":username", current_user.username))
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json' , 'X-HTTP-METHOD-OVERRIDE' => 'DELETE'})
    req.body = course
    res = http.request(req)

    redirect_to enrollments_path
  end


  #Edição
  def index
    # Edição acadêmica
    if (not params[:edx_course_id].blank?)
      res = get_response(EDX["host"] + params[:edx_course_id])
      @edx_courses  = JSON.parse("[" + res.body + "]")
      @resource_uri = params[:edx_course_id]
    else
      res = get_response(EDX_URLS["list_available_courses"])
      @edx_courses  = JSON.parse(res.body)["objects"]
    end
    render partial: 'edx_courses/index'
  end  

  def new
    @course = Course.new(params[:course])
    @courses_names = params[:courses_names]
  end

  def create
    create_user_solar_in_edx
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
   
  private

    def get_response(url)
      url = URI.parse(url)
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    end

    # verificar usuario
    def check_me
      url = URI.parse(EDX_URLS["verify_user"].gsub(":username", current_user.username))
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }

      begin
        res.value

        return true
      rescue
        return false
      end
    end

    def create_user_solar_in_edx
      unless check_me
        user = {username: current_user.username, name: current_user.name, email: current_user.email}.to_json
         
        uri  = URI.parse(EDX_URLS["insert_user"])
        http = Net::HTTP.new(uri.host,uri.port)

        req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = user
        res  = http.request(req)
      end  
    end  

end

class EdxCoursesController < ApplicationController

  layout false

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
          # res = get_response("http://10.0.4.163:8001"+uri_course)
          my_courses  << res.body << ","
        end

        my_courses = my_courses.chop
        my_courses = "[" + my_courses + "]"
        @courses = JSON.parse(my_courses)
      end
    end   
  end

  # listar cursos dispiniveis
  def available
    @available_courses, @my_courses = [], []

    ## todos
    res = get_response(EDX_URLS["list_available_courses"])
    @available_courses = JSON.parse(res.body)["objects"]
    @my_courses = my.map { |mc| mc['course_id'] } unless my.nil?
  
  end

  # matricular
  def enroll
    unless check_me
      user = {
      "username" => current_user.username, "name" => current_user.name, "email" => current_user.email
        }.to_json
       
      puts user 
      uri = URI.parse(EDX_URLS["insert_user"])
      http = Net::HTTP.new(uri.host,uri.port)

      http.set_debug_output($stdout)

      req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
      req.body = user
      res = http.request(req)

      puts "Informacoes chamada"
      puts uri.host
      puts uri.port
      puts uri.path
      puts "FIM"
    end  
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

end

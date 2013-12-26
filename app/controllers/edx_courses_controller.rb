class EdxCoursesController < ApplicationController

  layout false

  EDX_URLS = YAML::load(File.open('config/edx.yml'))[Rails.env.to_s]['urls']

  # listar cursos do usuario
  def my
    @courses = []

    if check_me
      res = get_response(EDX_URLS["list_users_courses"].gsub(":username", current_user.username))
      @courses = JSON.parse(res.body)["objects"]
    end
  end

  # listar cursos dispiniveis
  def available
    @courses, @my_courses = [], []

    if check_me
      ## meus cursos
      res_my_curses = get_response(EDX_URLS["list_users_courses"].gsub(":username", current_user.username))
      @my_courses = JSON.parse(res_my_curses.body)["objects"].map { |mc| mc['course_id'] }

      ## todos
      res = get_response(EDX_URLS["list_available_courses"])
      @courses = JSON.parse(res.body)["objects"]
    end
  end

  # matricular/cancelar matricula
  def enroll
    uri = URI(EDX_URLS["enroll_or_unenroll"].gsub(":username", current_user.username))
    res = Net::HTTP.post_form(uri, course_id: Base64.decode64(params[:course]), action: params[:type])

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

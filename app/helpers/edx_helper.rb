module EdxHelper

  EDX = YAML::load(File.open("config/edx.yml"))[Rails.env.to_s] rescue nil
  EDX_URLS = EDX["urls"] rescue nil

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
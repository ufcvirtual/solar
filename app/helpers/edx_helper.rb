module EdxHelper
       
    require 'net/http'

    # variável de classe
    @@version = 'dev';


    def user_edx(username)
      url = URI.parse('http://solaredxstd.virtual.ufc.br/solaredx/api/'+@@version+'/user/')
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http| 
        http.request(req)
      }
      users = JSON.parse(res.body)

      users_edx = Array.new
      
      users['objects'].each do|u|
        users_edx << u['username']
      end
      
      return users_edx.include?(username)
    end

    def available_courses()
      url = URI.parse('http://solaredxstd.virtual.ufc.br/solaredx/api/'+@@version+'/course/')
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http| 
        http.request(req)
      }
      courses =JSON.parse(res.body)
      return  courses['objects']
    end  

    def my_courses(username)
      url = URI.parse('http://solaredxstd.virtual.ufc.br/solaredx/api/'+@@version+'/user/'+username+'/course/')
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http| 
        http.request(req)
      }
      courses = JSON.parse(res.body)
      return  courses['objects']  
    end  

    def array_my_courses(username) 
      courses_enrollment = Array.new 
      my_courses(username).each do |mc|
        courses_enrollment << mc['course_id']
      end
      return courses_enrollment
    end      

    def enroll_or_unenroll(username,course,action) 
      uri = URI('http://solaredxstd.virtual.ufc.br/solaredx/api/'+@@version+'/user/'+username+'/course/')
      res = Net::HTTP.post_form(uri, 'course_id' => course, 'action' => action)
    end  

end    
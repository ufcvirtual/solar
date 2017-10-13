namespace :grape do
  desc "routes"
  task :routes => :environment do
    ApplicationAPI.routes.map do |route| 
    	puts "#{route.request_method} - #{route.path}\n"
    end
  end
end
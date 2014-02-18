class ApplicationAPI < Grape::API
  include APIGuard

  format :json
  formatter :json, Grape::Formatter::Rabl

  rescue_from ActiveRecord::RecordNotFound do |e|
    rack_response({}, 404)
  end

  helpers do
    ## only webserver can access
    def verify_ip_access!
      raise ActiveRecord::RecordNotFound unless YAML::load(File.open('config/webserver.yml'))[Rails.env.to_s]['address'].include?(request.env['REMOTE_ADDR'])
    end
  end

  mount V1::Base
end

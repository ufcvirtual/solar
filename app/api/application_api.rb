class ApplicationAPI < Grape::API
  include APIGuard

  format :json
  formatter :json, Grape::Formatter::Rabl

  rescue_from ActiveRecord::RecordNotFound do |e|
    rack_response({}, 404)
  end

  before { Rails.logger.info "[API] [INFO] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] params: #{ActionController::Parameters.new(params).except("route_info").as_json}" }

  helpers Helpers::V1::All
  mount V1::Base
end

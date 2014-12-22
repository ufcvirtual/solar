class ApplicationAPI < Grape::API
  include APIGuard

  format :json
  formatter :json, Grape::Formatter::Rabl

  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    rack_response(error.as_json , 404)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |error|
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [400] message: #{error}"
    rack_response(error.as_json, 400)
  end

  rescue_from CanCan::AccessDenied do |error|
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [401] message: #{error}"
    rack_response(error.as_json, 401)
  end

  rescue_from :all do |error|
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [422] message: #{error}"
    rack_response(error, 422)
  end

  before { Rails.logger.info "[API] [INFO] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] params: #{ActionController::Parameters.new(params).except("route_info").as_json}" }

  helpers Helpers::V1::All
  mount V1::Base

  ## helper geral
  helpers do
   def authorize!(*args)
     guard!
     ::Ability.new(current_user).authorize!(*args)
   end
  end
end

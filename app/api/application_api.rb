require 'doorkeeper/grape/helpers'

class ApplicationAPI < Grape::API
  helpers Doorkeeper::Grape::Helpers
  include APIGuard
  include APILogInfo

  format :json
  formatter :json, Grape::Formatter::Rabl

  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    rack_response(error.as_json , 404)
    error!({ error: error.as_json }, 404)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |error|
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [400] message: #{error} #{error.try(:errors).try(:as_json)}"
    rack_response(error.try(:errors).try(:as_json), 400)
    error!({ error: error.try(:errors).try(:as_json) }, 400)
  end

  rescue_from CanCan::AccessDenied do |error|
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [401] message: #{error}"
    rack_response(error.as_json, 401)
    error!({ error: error.as_json }, 401)
  end

  rescue_from :all do |error|
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [422] message: #{error}"
    if ['nonexistent_file', 'exam', 'cant_open_file'].include?(error.to_s)
      rack_response(error.as_json, 422)
      error!({ error: error.to_s }, 422)
    else
      rack_response(error.as_json, 422)
      error!({ error: error.as_json }, 422)
    end
  end

  before { Rails.logger.info "[API] [INFO] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [#{request.headers['Client-Ip']}] params: #{ActionController::Parameters.new(params).except("route_info", "access_token").as_json}" }
  after { Rails.logger.info "[API] [FINISHED] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [#{request.headers['Client-Ip']}] params: #{ActionController::Parameters.new(params).except("route_info", "access_token").as_json}" }

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

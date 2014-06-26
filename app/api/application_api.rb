class ApplicationAPI < Grape::API
  include APIGuard

  format :json
  formatter :json, Grape::Formatter::Rabl

  rescue_from ActiveRecord::RecordNotFound do |e|
    rack_response({}, 404)
  end

  mount V1::Base
end

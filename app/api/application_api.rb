class ApplicationAPI < Grape::API
  include APIGuard

  format :json

  formatter :json, Grape::Formatter::Rabl

  mount V1::Base
end

module V1
  class Routes < Base
    namespace :routes
    get do
      ApplicationAPI::routes
    end
  end
end

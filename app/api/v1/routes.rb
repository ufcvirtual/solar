module V1
  class Routes < Base
    namespace :routes
    get do
      routes = ApplicationAPI::routes.map do |route|
        next if params[:filter].present? && !route.route_path.include?(params[:filter])
        {
          description: route.route_description,
          method: route.route_method,
          path: route.route_path,
          params: route.route_params
        }.reject { |k,v| !v.present? }
      end
      routes.compact
    end
  end
end

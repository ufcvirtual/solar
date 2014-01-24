# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'grape/rabl'

use Rack::Config do |env|
  env['api.tilt.root'] = 'app/api/templates'
end

run Solar::Application

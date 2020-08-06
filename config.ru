# This file is used by Rack-based servers to start the application.

if ENV['RAILS_ENV'] == 'production'
  # Unicorn self-process killer
  # require 'unicorn/configuration'
  #require 'unicorn/worker_killer'

  # Max requests per worker
  #use Unicorn::WorkerKiller::MaxRequests, 500, 600, true

  # Max memory size (RSS) per worker
  #use Unicorn::WorkerKiller::Oom, (192*(1024**2)), (256*(1024**2)), 16, true
end

require ::File.expand_path('../config/environment',  __FILE__)

run Solar::Application

if (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['run_websocket'] rescue false)
  system "ruby lib/websockets/websocket_server.rb&"
end

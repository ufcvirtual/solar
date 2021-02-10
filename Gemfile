source "http://rubygems.org"

ruby "2.5.7"

#gem "rails", "~> 3.2.16"
gem 'rails', '5.1.7'
gem "rack", "~> 2.0.0"
gem "rake", "~> 10.1.1"
gem "pg", "~> 0.21.0"
#gem "foreigner", "~> 1.4.0"

# gem "koala", "1.2.0" # facebook

gem "devise", "~> 4.4.3"
gem "devise-i18n", "~> 1.6.5"
gem "cancancan", "~> 2.2.0"
gem "devise-encryptable", "~> 0.2.0"

gem "chronic", "0.6.1"
#gem "brazilian-rails", "~> 3.3.0"
gem 'simple_form', "~> 4.0.1"

gem "paperclip", "~> 4.3.7"
gem "will_paginate", "~> 3.1.6"
gem "jquery-rails", "~> 4.3.3"
gem 'jquery-ui-rails', '~> 6.0.1'
gem 'rails-assets-fancyBox', '2.1.6', source: 'https://rails-assets.org'
#gem "fancybox2-rails", "~> 0.2.5"

gem "haml", "~> 5.0.4"
gem "haml-rails", "~> 1.0.0", group: :development
# gem "ckeditor", "~> 4.0.11"
gem "ckeditor", ">= 4.2.4"

gem "fullcalendar-rails", "~> 2.0.2.0"
gem "momentjs-rails", "~> 2.9.0"

gem "bigbluebutton-api-ruby", "~> 1.6.0"

# platform adicionado para evitar que o unicorn tente ser executado no windows
gem "puma", "~> 4.3.5"

gem "rubyzip", "~> 1.2.1"

gem "doorkeeper", "~> 4.3.2"
gem "rack-oauth2", "~> 1.9.3"
gem "grape", "~> 1.0.3"
gem "rabl", "~> 0.13.1"
gem "grape-rabl", "~> 0.4.3"

gem "savon", "~> 2.0.0" # comunicação com ws

gem "roo", "~> 1.13.2"  # csv, excel
gem "prawn", "~> 2.0.1" # pdf
gem "prawn-table", "~> 0.2.2"
#gem "pdfkit" #pdf
gem "wicked_pdf", "~> 1.1.0"
gem "wkhtmltopdf-binary", "~> 0.12.3" #pdf

gem "em-websocket", "~> 0.5.1" # websocket pros fóruns

# gem "strong_parameters", "~> 0.2.3" # a partir do rails 4 ele faz parte do rails core

gem 'hairtrigger', '~> 0.2.24' # triggers

gem 'nested_form_fields', '~> 0.8.4'
gem "coffee-rails", "~> 4.2.2"

gem "rest-client", "~> 2.0.2"

gem "rufus-scheduler", "~> 3.4.2"

# fila de emails
gem "daemons"
gem "delayed_job_active_record", "~> 4.1.5"

gem "activerecord-session_store", "~> 1.1.3"

# add these gems to help with the transition:
#gem 'protected_attributes', '~> 1.0.9'
#gem 'rails-observers'
#gem "actionpack", "4.1.8"
gem "actionpack-page_caching", "~> 1.2.3"
gem "actionpack-action_caching", "~> 1.2.0"

gem "execjs"
gem "therubyracer", platforms: :ruby
gem "uglifier", "~> 4.1.10"
gem "sass-rails", "~> 5.0.7"
gem "compass-rails", "~> 4.0.0"

gem "htmlentities", "~> 4.3.4"
gem "newrelic_rpm"

gem "dotenv-rails"

group :development do
  gem "foreman", require: false

  gem "sshkit-sudo" # usar sudo no capistrano
  gem "capistrano", "~> 3.0"
  gem "capistrano-rails"
  gem "capistrano3-delayed-job"
  gem "capistrano-nvm"
  gem "capistrano-rvm"
  gem "capistrano3-puma"
  gem "capistrano3-nginx"
  gem 'capistrano-dotenv-tasks', require: false

  gem "rb-readline", "~> 0.5.1"
  #gem "spork", "~> 0.9.2"
  # gem "thin" # server local melhor
  gem "better_errors", "~> 2.4.0"
  gem "binding_of_caller", "~> 0.8.0" # better 'better errors'
  #gem "quiet_assets", "~> 1.1.0" # nao mostra log de assets em development
  gem "rack-mini-profiler", "~> 0.10.7"
  # For memory profiling (requires Ruby MRI 2.1+)
  gem "memory_profiler", "~> 0.9.10"

  # For call-stack profiling flamegraphs (requires Ruby MRI 2.0.0+)
  gem "flamegraph", "~> 0.9.5"
  gem "stackprof", "~> 0.2.11"     # For Ruby MRI 2.1+
  gem "fast_stack", "~> 0.2.0"    # For Ruby MRI 2.0

  gem "cpf_utils", "~> 1.2.1"
  gem "faker", "~> 1.8.7"
end

group :development, :test do
  gem "awesome_print"
  gem "pry-rails"
  gem "pry-rescue"
  gem "factory_girl_rails", "~> 4.2.1"
  #gem "rspec-rails", "~> 3.4.0"
  gem 'test-unit', '~> 3.1.5'
  gem "rubocop", "~> 0.52.1", require: false # A Ruby static code analyzer, based on the community Ruby style guide.
end

group :test do
  gem "webrat", "0.7.3"
  gem "capybara", "~> 2.18.0"
  gem "database_cleaner", "0.7.2"
  gem "cucumber-rails", "~> 2.2.0", require: false
  gem "selenium-webdriver", "~> 3.142.7"
  gem "launchy", "2.5.0"
  gem "nokogiri", "1.11.1" # html, css parser (search)
  # gem "spreewald", "0.8.4" # collection of cucumber steps
  gem "simplecov", "~> 0.15.1", require: false # cobertura de testes
end
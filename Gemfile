source "http://rubygems.org"

ruby "2.3.6"

gem 'rails', '5.1.6'
gem "rack", "~> 2.0.0"
gem "rake", "~> 10.1.1"
gem "pg", "~> 0.21.0"

gem 'actionpack-page_caching'
gem 'actionpack-action_caching'

#gem "koala", "2.4.0" # facebook

gem "devise", "~> 4.4.3"
gem "devise-i18n", "~> 1.6.2"
gem 'cancancan', '~> 2.2.0'
gem "devise-encryptable", "~> 0.2.0"

gem "chronic", "0.6.1"
gem 'simple_form', "~> 4.0.0"

gem "paperclip", "~> 4.3.7"
gem "will_paginate", "~> 3.1.6"
gem "jquery-rails", "~> 4.3.3"
gem 'jquery-ui-rails', '~> 6.0.1'
#gem "fancybox3", "~> 0.1.1"
#gem 'rails-assets-fancyBox', source: 'https://rails-assets.org'
gem 'rails-assets-fancyBox', '2.1.6', source: 'https://rails-assets.org'

gem "haml", "~> 5.0.4"
gem "haml-rails", "~> 1.0.0", group: :development
gem "ckeditor", ">= 4.2.4"

gem "fullcalendar-rails", "~> 3.4.0.0"
gem "momentjs-rails", "~> 2.20.1"

gem "bigbluebutton-api-ruby", "~> 1.6.0"

# platform adicionado para evitar que o unicorn tente ser executado no windows
gem "unicorn", "~> 5.4.0", platform: :ruby
gem 'unicorn-worker-killer', '~>0.4.4' # gerenciar os workers do unicorn
gem "passenger", "~> 5.2.3"

gem "rubyzip", "~> 1.2.1"

gem "doorkeeper", "~> 4.3.2"
gem "rack-oauth2", "~> 1.9.1"
gem "grape", "~> 1.0.2"
gem "rabl", "~> 0.13.1"
gem "grape-rabl", "~> 0.4.3"
#gem 'wine_bouncer', '~> 1.0.2'

gem "savon", "~> 2.0" # comunicação com ws

gem "roo", "~> 1.13.2"  # csv, excel
gem "prawn", "~> 2.0.1" # pdf
gem 'prawn-table'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'#pdf

gem "em-websocket" # websocket pros fóruns

gem 'hairtrigger', '~> 0.2.20' # triggers

gem 'nested_form_fields', '~> 0.8.2'
gem 'coffee-rails'

gem 'rest-client'

gem 'rufus-scheduler'

#fila de emails
gem 'delayed_job_active_record'
gem 'delayed_job'

gem 'activerecord-session_store'

# add these gems to help with the transition:
#gem 'protected_attributes'
group :development do
  gem "rb-readline", "~> 0.5.1"
  gem "net-ssh", "~> 2.6.8" # dependencia capistrano
  gem "rvm-capistrano", "~> 1.5.5"
  gem "capistrano", "~> 2.15.9"
  #gem "spork", "~> 0.9.2"
  gem "thin" # server local melhor
  gem "better_errors"
  gem "binding_of_caller" # better 'better errors'
  gem "sprockets-rails" # nao mostra log de assets em development
  gem 'rack-mini-profiler'
  # For memory profiling (requires Ruby MRI 2.1+)
  gem 'memory_profiler'

  # For call-stack profiling flamegraphs (requires Ruby MRI 2.0.0+)
  gem 'flamegraph'
  gem 'stackprof'     # For Ruby MRI 2.1+
  gem 'fast_stack'    # For Ruby MRI 2.0

  gem 'cpf_utils'
  gem 'faker'
end

group :development, :test do
  gem "pry-rails" # console melhor
  gem "pry-rescue"
  gem "factory_girl_rails", "~> 4.2.1"
  gem "factory_girl", "~> 4.2.0"
  gem "rspec-rails", "~> 3.7.2"
  gem 'test-unit', '~> 3.1.5'
  gem "rubocop", require: false # A Ruby static code analyzer, based on the community Ruby style guide.
end

group :test do
  gem "webrat", "0.7.3"
  gem "capybara"
  gem "database_cleaner", "1.7.0"
  gem "cucumber-rails", "~> 1.6.0", require: false
  gem "selenium-webdriver", "~> 3.11.0"
  gem "launchy", "2.4.3"
  gem "nokogiri" # html, css parser (search)
  # gem "spreewald", "0.8.4" # collection of cucumber steps
  gem "simplecov", require: false # cobertura de testes
end


group :assets do
  gem "uglifier", "~> 4.1.10"
  gem "sass-rails", "~> 5.0.7"
  gem "compass-rails", "~> 3.0.2"
end

# new relic
#gem 'newrelic_rpm'

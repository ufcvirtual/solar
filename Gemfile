source "http://rubygems.org"

ruby "2.1.0"

gem "rails", "~> 3.2.16"
gem "rack", "~> 1.4.5"
gem "rake", "~> 10.1.1"
gem "pg", "~> 0.15.0"
gem "foreigner", "~> 1.4.0"

gem "koala", "1.2.0" # facebook

gem "devise", "~> 3.4.1"
gem "devise-encryptable", "~> 0.2.0"
gem "devise-i18n", "~> 0.11.3"
gem "cancan", "~> 1.6.10"

gem "chronic", "0.6.1"
gem "brazilian-rails", "~> 3.3.0"
gem "simple_form", "~> 2.1.1"

gem "paperclip", "~> 3.4.2"
gem "will_paginate", "~> 3.0.7"
gem "jquery-rails", "~> 2.2.2"
gem "fancybox2-rails", "~> 0.2.5"

gem "haml", "~> 4.0.5"
gem "haml-rails", "~> 0.4.0", group: :development
gem "ckeditor", "~> 4.0.11"

gem "fullcalendar-rails", "~> 1.6.4.0"
gem "momentjs-rails", "~> 2.8.3"

gem "xmpp4r", "~> 0.5.5"
gem "bigbluebutton-api-ruby", "~> 1.2.0"

# platform adicionado para evitar que o unicorn tente ser executado no windows
gem "unicorn", "~> 4.6.3", platform: :ruby

gem "rubyzip", "~> 1.0.0"

gem "doorkeeper", "~> 1.4.1"
gem "rack-oauth2", "~> 1.0.7"
gem "grape", "~> 0.9.0"
gem "rabl", "~> 0.11.0"
gem "grape-rabl", "~> 0.3.0"

gem "savon", "~> 2.0" # comunicação com ws

gem "roo", "~> 1.13.2" # csv, excel

gem "em-websocket" # websocket pros fóruns

gem "strong_parameters", "~> 0.2.3"

gem 'hairtrigger', '~> 0.2.12' # triggers

group :development do
  gem "rb-readline", "~> 0.5.1"
  gem "net-ssh", "~> 2.6.8" # dependencia capistrano
  gem "rvm-capistrano", "~> 1.5.5"
  gem "capistrano", "~> 2.15.4"
  gem "spork", "~> 0.9.2"
  gem "thin" # server local melhor
  gem "better_errors"
  gem "binding_of_caller" # better 'better errors'
  gem "quiet_assets" # nao mostra log de assets em development
end

group :development, :test do
  gem "pry-rails" # console melhor
  gem "pry-rescue"
  gem "factory_girl_rails", "~> 4.2.1"
  gem "rspec-rails", "~> 2.14.1"
end

group :test do
  gem "webrat", "0.7.3"
  gem "capybara", "2.3.0"
  gem "database_cleaner", "0.7.2"
  gem "cucumber-rails", "~> 1.3.1", require: false
  gem "selenium-webdriver", "~> 2.42.0"
  gem "launchy", "2.1.0"
  gem "nokogiri", "1.5.5"
  # gem "spreewald", "0.8.4" # collection of cucumber steps
  # gem "simplecov", ">= 0.5.3", :require => false
end

group :assets do
  gem "uglifier", "~> 1.3.0"
  gem "sass-rails", "~> 3.2.6"
  gem "compass-rails", "~> 1.1.3"
end

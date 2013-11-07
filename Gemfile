source "http://rubygems.org"
#Teste
gem "rails", "~> 3.2.13"
gem "rack", "~> 1.4.5"
gem "rake", "~> 10.0.4"
gem "pg", "~> 0.15.0"
gem "foreigner", "~> 1.4.0"
gem "koala", "1.6.0"

gem "devise", "~> 2.2.3"
gem "devise-encryptable", "~> 0.1.1"
gem "cancan", "~> 1.6.9"

gem "chronic", "0.6.1"
gem "brazilian-rails", "~> 3.2.0"
gem "simple_form", "~> 2.1.0"

gem "paperclip", "~> 3.4.1"
gem "will_paginate", "~> 3.0.4"
gem "jquery-rails", "~> 2.2.1"
gem "fancybox2-rails", "~> 0.2.4"

gem "factory_girl_rails", "~> 4.2.1", :group => [:development, :test]
gem "rspec-rails", "~> 2.13.0", :group => [:development, :test]

gem "haml", "~> 4.0.1"
gem "haml-rails", "~> 0.4", :group => :development
gem "ckeditor", "~> 4.0.6"

gem "fullcalendar-rails", "~> 1.6.4.0"

# platform adicionado para evitar que o unicorn tente ser executado no windows
gem "unicorn", "~> 4.6.2", :platform => :ruby

gem "rubyzip", "~> 1.0.0"

group :development do
  gem "rb-readline", "~> 0.4.2"
  gem "net-ssh", "~> 2.6.6" # dependencia capistrano
  gem "rvm-capistrano", "~> 1.2.7"
  gem "capistrano", "~> 2.14.2"
  gem "spork", "~> 1.0rc"
end

group :test do
  gem "webrat", "0.7.3"
  gem "capybara", "1.1.2"
  gem "database_cleaner", "0.7.2"
  gem "cucumber-rails", "~> 1.3.1", :require => false
  gem "launchy", "2.1.0"
  gem "nokogiri", "1.5.5"
  gem 'spreewald'
  # gem "simplecov", ">= 0.5.3", :require => false
end

group :assets do
  gem "uglifier", "~> 1.3.0"
  gem "sass-rails", "~> 3.2.6"
  gem 'compass-rails'
end

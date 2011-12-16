source 'http://rubygems.org'

gem 'rails', '3.0.11'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg', '0.11.0'
gem 'rack', '1.2.1'
gem 'rake', '0.9.2.2'

#Teste (alternativa ao metric_fu)
gem 'simplecov', '>= 0.5.3', :require => false, :group => :test


# gem para geracao automatica de relacionamentos
gem 'automatic_foreign_key', '1.2.0'

# paginacao
gem 'will_paginate', "~> 3.0.pre2" #Will paginate padrão é bugada com o rails 3 :/

# autoriazacao com cancan
gem 'cancan', '1.6.5'

# Gem usada para personalizar data,moeda etc para padroes brasileiros
gem 'brazilian-rails', '3.0.4'
gem 'factory_girl_rails', '1.0'
gem 'chronic', '0.6.1'
# para uso da gem authlogic (autenticacao)
#gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'
gem 'devise', '1.4.9'
gem 'rails3-generators', '0.17.4'
gem 'paperclip', :git => 'git://github.com/thoughtbot/paperclip.git'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and lrake tasks are available in development mode:
group :development, :test do
  gem 'capistrano'
  gem 'webrat', '0.7.3'
  gem 'capybara', '1.0.0'
  gem 'database_cleaner', '0.6.7'
  gem 'cucumber', '1.0.2'
  gem 'cucumber-rails', '1.0.2'
  gem 'rspec', '2.6.0'
  gem 'rspec-rails', '2.6.1'
  gem 'spork', '0.8.5'
  gem 'launchy', '2.0.4'    # So you can do Then show me the page
  gem 'silent-postgres'     # Omitindo os logs demasiados do adapter do postgres.
end

source 'http://rubygems.org'

gem 'rails', '3.0.7'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg', '0.9.0'
gem 'rack', '1.2.1'
gem 'rake', '0.8.7'

# gem para geracao automatica de relacionamentos
gem 'automatic_foreign_key', '1.2.0'

# paginacao
gem 'will_paginate', "~> 3.0.pre2" #Will paginate padrão é bugada com o rails 3 :/

# autoriazacao com cancan
gem 'cancan', '1.6.4'

# Gem usada para personalizar data,moeda etc para padroes brasileiros
gem 'brazilian-rails', '3.0.2'
gem 'factory_girl_rails', '1.0'
gem 'chronic', '0.3.0'
# para uso da gem authlogic (autenticacao)
gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'
gem 'rails3-generators', '0.14.0'
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
# and rake tasks are available in development mode:
group :development, :test do
  gem 'webrat', '0.7.2'
  gem 'capybara', '0.4.0'
  gem 'database_cleaner', '0.6.0'
  gem 'cucumber', '0.9.4'
  gem 'cucumber-rails', '0.3.2'
  gem 'rspec', '2.5.0'
  gem 'rspec-rails', '2.5.0'
  gem 'spork', '0.8.4'
  gem 'launchy', '0.3.7'    # So you can do Then show me the page
  gem 'silent-postgres'     # Omitindo os logs demasiados do adapter do postgres.
end

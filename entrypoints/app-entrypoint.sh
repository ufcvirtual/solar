#!/bin/sh

set -e

# Remove a potentially pre-existing server.pid for Rails.
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# If the database exists, migrate. Otherwise setup (create and migrate)
# bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:create db:migrate
# echo "Database created & migrated!"

# Run the Rails server
bundle exec rails server -b 0.0.0.0 -p 8080
# bundle exec foreman s

# http://equinox.one/blog/2016/04/20/Docker-with-Ruby-on-Rails-in-development-and-production/

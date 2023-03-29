ARG RUBY_VERSION=2.7.2
FROM ruby:$RUBY_VERSION-slim AS railsbuilder

ARG build_without=""
ENV BUNDLE_WITHOUT=${bundle_without}

ARG BUILD_PACKAGES="build-essential libpq-dev imagemagick gnupg2 shared-mime-info"

RUN apt-get update && apt-get install -y $BUILD_PACKAGES

ENV BUNDLER_VERSION=2.1.4

WORKDIR /app

COPY Gemfile* .

RUN gem install bundler -v 2.1.4 && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle check || bundle install

COPY . .

RUN bundle exec rails assets:precompile \
    && rm -rf /usr/local/bundle/gems/cache/*.gem \
    && find /usr/local/bundle/gems/ -name "*.c" -delete \
    && find /usr/local/bundle/gems -name "*.o" -delete
# && rm -rf spec node_modules app/assets vendor/assets lib/assets tmp/cache

FROM ruby:$RUBY_VERSION-slim AS runner

ARG RUN_PACKAGES="libpq-dev imagemagick gnupg2 shared-mime-info"

RUN apt-get update && apt-get install -y $RUN_PACKAGES

WORKDIR /app

COPY --from=railsbuilder /usr/local/bundle /usr/local/bundle
COPY --from=railsbuilder /app/ .

# CMD ["bundle", "exec", "rails s -b 0.0.0.0"]
ENTRYPOINT ["./entrypoints/app-entrypoint.sh"]
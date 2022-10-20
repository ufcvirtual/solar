FROM ruby:2.7.2-slim AS railsbuild

ARG build_without=""
ENV BUNDLE_WITHOUT=${bundle_without}

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    make \
    automake \
    autoconf  \
    libpq-dev \
    imagemagick \
    gnupg2 \
    shared-mime-info

RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y nodejs yarn

FROM railsbuild

ENV BUNDLER_VERSION=2.1.4

WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock ./

RUN gem install bundler -v 2.1.4 && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle check || bundle install && \
    yarn install --check-files

COPY . .

RUN bundle exec rails assets:precompile \
        && rm -rf /usr/local/bundle/gems/cache/*.gem \
        && find /usr/local/bundle/gems/ -name "*.c" -delete \
        && find /usr/local/bundle/gems -name "*.o" -delete \
        && rm -rf spec node_modules app/assets vendor/assets lib/assets tmp/cache

# CMD ["bundle", "exec", "rails s -b 0.0.0.0"]
ENTRYPOINT ["./entrypoints/app-entrypoint.sh"]
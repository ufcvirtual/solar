ARG RUBY_PATH=/usr/local/
ARG RUBY_VERSION=2.7.2

FROM ubuntu:16.04 AS rubybuild
ARG RUBY_PATH
ARG RUBY_VERSION

RUN apt-get update && \
  apt-get install -y \
  build-essential \
  zlib1g \
  zlib1g-dev \
  libpq-dev \
  libssl-dev \
  libyaml-dev \
  libxml2-dev \
  libxslt1-dev \
  libc6-dev \
  libncurses5-dev \
  libreadline-dev \
  libtool \
  make \
  automake \
  autoconf  \
  libffi-dev \
  unzip \
  imagemagick \
  sed \
  mawk \
  curl \
  openssl \
  apt-transport-https \
  ca-certificates \
  musl-dev \
  postgresql-client \
  gnupg2 \
  git

RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y yarn

RUN git clone git://github.com/rbenv/ruby-build.git $RUBY_PATH/plugins/ruby-build \
  && $RUBY_PATH/plugins/ruby-build/install.sh && \
  ruby-build $RUBY_VERSION $RUBY_PATH

###############

FROM rubybuild
ARG RUBY_PATH
ENV PATH $RUBY_PATH/bin:$PATH

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY --from=rubybuild $RUBY_PATH $RUBY_PATH

COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v 2.0.2 && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle check || bundle install

COPY package.json yarn.lock ./

RUN yarn install --check-files

COPY . $APP_HOME

# CMD ["bundle", "exec", "rails s -b 0.0.0.0"]

# ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]

# docker-compose up --build
# docker-compose exec app bundle exec rake db:setup
# docker-compose exec app bundle exec rake db:setup db:migrate

# https://ledermann.dev/blog/2018/04/19/dockerize-rails-the-lean-way/

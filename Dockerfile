ARG RUBY_PATH=/usr/local/
ARG RUBY_VERSION=2.3.8

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
  git \
  curl

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

RUN gem install bundler -v 1.17.3 && \
  bundle config build.nokogiri --use-system-libraries && \
  bundle check || bundle install

COPY . $APP_HOME

# CMD ["bundle", "exec", "rails s -b 0.0.0.0"]

# ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]

# docker-compose up --build
# docker-compose exec app bundle exec rake db:setup
# docker-compose exec app bundle exec rake db:setup db:migrate

# https://ledermann.dev/blog/2018/04/19/dockerize-rails-the-lean-way/

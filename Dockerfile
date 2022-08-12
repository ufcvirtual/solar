FROM ruby:2.7.2

RUN bundle config --global frozen 1

WORKDIR /app

RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y yarn

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install --check-files

COPY . .

RUN bundle exec rails assets:precompile

# CMD ["bundle", "exec", "rails s -b 0.0.0.0"]
ENTRYPOINT ["./entrypoints/app-entrypoint.sh"]
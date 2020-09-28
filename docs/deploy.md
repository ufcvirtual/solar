# Configuração de servidores

## Ubuntu

### Pacotes necessários

    sudo apt install build-essential \
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
                     ncurses-term \
                     make \
                     automake \
                     autoconf  \
                     libffi-dev \
                     unixodbc-dev \
                     silversearcher-ag \
                     software-properties-common \
                     unzip \
                     imagemagick \
                     sed \
                     mawk \
                     curl \
                     openssl \
                     nginx \
                     apt-transport-https \
                     ca-certificates \
                     postgresql-client

### RVM package for Ubuntu

  https://github.com/rvm/ubuntu_rvm

  #### Install old ruby 2.3.x on latest Ubuntu 20.04

    https://www.garron.me/en/linux/install-ruby-2-3-3-ubuntu.html

  #### Instalar ruby com RVM

    rvm install 2.3.8
    rvm use 2.3.8 --default

### NVM

  https://github.com/nvm-sh/nvm

    nvm install node 14.7.0
    nvm alias default node

## Deploy com capistrano

  ## Setup local

  Definir variaveis de ambiente num .env

      # Servidores de aplicacao.
      SOLAR_APP_SERVERS=user@solar.server1,user@solar.server2,...

      # Servidores de banco. Usado para migrations.
      SOLAR_APP_DBS=user@solar.db1

      # Onde os jobs serao executados.
      SOLAR_APP_JOBS=user@solar.jobs1

  ## Setup remoto

  Configuração do puma e nginx

    sudo rm /etc/nginx/sites-enabled/default

  Nginx sem certificado (usar apenas um)

    sudo ln -s /var/www/html/solar/shared/config/scripts/nginx/puma_solar_production /etc/nginx/sites-enabled/

  Nginx com certificado

    sudo ln -s /var/www/html/solar/shared/config/scripts/nginx/puma_solar_production_ssl /etc/nginx/sites-enabled/

  Reinicar o nginx

    sudo systemctl restart nginx

  Configuração inicial de diretórios

    foreman run cap production deploy:check

  Clonar arquivos config no servidor e fazer devidas modifiações

    git clone git@github.com:wedsonlima/solar2-config-files.git /var/www/html/solar/shared/config

  ## Deploy

    foreman run cap production deploy --roles=app,db,jobs
    foreman run cap production puma:stop
    foreman run cap production puma:start
    foreman run cap production delayed_job:restart

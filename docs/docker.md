# Docker

  * [overview](https://docs.docker.com/get-started/overview)

  * [compose and rails](https://docs.docker.com/compose/rails)

## Instalações

  * [docker](https://docs.docker.com/engine/install/ubuntu)

  * [docker compose](https://docs.docker.com/compose/install)

  Obs.: Sugiro colocar o seu usuário no grupo do docker para evitar executar os comandos como sudo. Aqui está um [exemplo](https://docs.docker.com/engine/install/linux-postinstall) de como fazer isso.

# Solar

### Construir imagens e rodar local

  Se o Dockerfile ou o docker-compose.yml sofrer modificação as imagens devem ser refeitas

    docker-compose build

  Para subir a aplicação

    docker-compose up

  Para subir a aplicação liberando o terminal

    docker-compose up -d

  Os passos anteriores podem ser feitos ao mesmo tempo

    docker-compose up --build

  Listando os logs

    docker-compose logs -f -t

### Outros exemplos

  Com os containers rodando você pode acessar o bash do app

    docker-compose exec app bash

  Para rodar as migrations

    docker-compose exec app bundle exec rake db:migrate

  Acessar o banco

    docker-compose exec database psql -U solar

  Ver logs do app

    docker-compose exec app tail -f log/development.log

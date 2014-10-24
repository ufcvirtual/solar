Usuários
========

Neste item estarão dispostas as chamadas, à API, existentes para os dados dos usuários.

1. Dados pessoais
-----------------

Objetivo
~~~~~~~~
  Retorna os dados do usuário corrente.

Chamada
~~~~~~~
  GET users/me

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*
  
Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer
  2. Na resposta, o parâmetro photo retorna a url de chamada à api para obter a foto do usuário.

Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { 
      id: 1, 
      name: "Nome do usuário", 
      username: "Username/Login do usuário", 
      email: "Email do usuário", 
      photo: "/api/v1/users/1/photo"
    }

2. Dados de um usuário
----------------------

Objetivo
~~~~~~~~
  Retorna os dados de um determinado usuário.

Chamada
~~~~~~~
  GET users/:id

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer
  2. Na resposta, o parâmetro photo retorna a url de chamada à api para obter a foto do usuário.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { 
      id: 1, 
      name: "Nome do usuário", 
      username: "Username/Login do usuário", 
      email: "Email do usuário", 
      photo: "/api/v1/users/1/photo"
    }

3. Recuperação da foto de um usuário
------------------------------------

Objetivo
~~~~~~~~
  Recuperar a foto de um usuário.

Chamada
~~~~~~~
  GET users/:id/photo

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer
  
Resposta
~~~~~~~~
  - Foto do usuário.

4. Criação de usuário
---------------------

Objetivo
~~~~~~~~
  Criar um usuário.

Chamada
~~~~~~~
  POST /user

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     name: "Usuário",
     nick: "User",
     cpf: "00000000000",
     email: "usuario@email.com",
     gender: true,
     birthdate: "1985-10-15",
     username: "login_do_usuário",
     cellphone: "00000000",
     telephone: "00000000",
     address: "Rua A",
     address_number: "111",
     address_neighborhood: "Bairro A",
     zipcode: "00000000",
     country: "País A",
     state: "Estado A",
     city: "Cidade A",
     institution: "UFC",
     special_needs: "Visual"
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - name: String (de 6 à 90 caracteres)
    - nick: String (de 3 à 34 caracteres)
    - cpf, email: String
    - gender: Boolean (se true, masculino; se false, feminino)
    - birthdate: Date
  2. Parâmetros opcionais
    - username: String (de 3 à 20 caracteres)
    - institution: String (até 120 caracteres)
    - country, address, city: String (até 90 caracteres)
    - zipcode: String (até 9 caracteres)
    - address_neighborhood: String (até 49 caracteres)
    - cell_phone, telephone, address_number, state, special_needs
  3. Se um username (login) não for informado, será definido como sendo o cpf.
  4. Ao cadastrar o usuário, uma senha aleatória é gerada automaticamente e enviada para o email desse.
  5. Se o usuário já existir no ambiente, nada dele é alterado e seu id é retornado na resposta.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { id: 1 }

5. Importar usuário do Módulo Acadêmico
---------------------------------------

Objetivo
~~~~~~~~
  Importa usuário do módulo acadêmico. Se usuário existe, atualiza dados; Caso contrário, cria.

Chamada
~~~~~~~
  POST user/import/:cpf

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - cpf: String

Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1, 
        code: "Código", 
        name: "Nome da disciplina" 
      }, {...}
    ]

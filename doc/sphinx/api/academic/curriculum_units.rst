Disciplinas
===========

1. Lista de disciplinas da oferta corrente
------------------------------------------

Objetivo
~~~~~~~~
  Retorna a lista de disciplinas do usuário logado e da oferta vigente. Futuramente, poderemos especificar outra oferta.

Chamada
~~~~~~~
  GET /curriculum_units/

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*
  
Observações
~~~~~~~~~~~
  *Nenhuma observação.*

Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1,
        code: "RM404",
        name: "Introducao a Linguistica"
      }, {...}
    ]

2. Lista de disciplinas pela oferta corrente com suas respectivas turmas
------------------------------------------------------------------------

Objetivo
~~~~~~~~
  Retorna a lista de disciplinas do usuário logado e da oferta vigente com suas respectivas turmas. Futuramente, poderemos especificar outra oferta.

Chamada
~~~~~~~
  GET /curriculum_units/groups

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  *Nenhuma observação.*
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1,
        code: "RM404",
        name: "Introducao a Linguistica"
        groups: [
          {
            id: 1,
            code: "FOR",
            semester: "2011.1"
          }, {...}
        ]
      }, {...}
    ]

3. Criação de disciplina
------------------------

Objetivo
~~~~~~~~
  Criar uma disciplina.

Chamada
~~~~~~~
  POST curriculum_unit

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     name: "Disciplina01",
     code: "D01",
     curriculum_unit_type_id: 1,
     resume: "Resumo",
     syllabus: "Ementa",
     prerequisites: "Pré-requisitos",
     passing_grade: 7,
     working_hours: 80,
     credits: 4,
     update_if_exists: false
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - name: String
    - code: String (máximo de 40 caracteres)
    - curriculum_unit_type_id: Integer (ver DOC)
  2. Parâmetros opcionais
    - resume, syllabus, objectives, prerequisites: String
    - passing_grade: Float
    - working_hours: Integer
    - update_if_exists: Boolean (por padrão, se não for informado, é definido como falso. se for verdadeiro, ao tentar criar a disciplina e ela já existir, seus dados serão apenas atualizados e não será retornado um erro de "já existente")
  3. Se for uma disciplina com curriculum_unit_type_id sendo 3 (livre), é criado um curso associado. Portanto, na resposta, é informado o id do curso. Para os demais tipos, course_id será nil.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { 
      id: 1,
      course_id: nil
    }

4. Edição de disciplina
------------------------

Objetivo
~~~~~~~~
  Editar uma disciplina já existente.

Chamada
~~~~~~~
  PUT curriculum_unit/:id

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     name: "Disciplina01",
     code: "D01",
     curriculum_unit_type_id: 1,
     resume: "Resumo",
     syllabus: "Ementa",
     prerequisites: "Pré-requisitos",
     passing_grade: 7,
     working_hours: 120,
     credits: 6
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer (id da disciplina em questão)
    - ao menos um dos parâmetros opcionais se faz obrigatório
  2. Parâmetros opcionais
    - name, code, resume, syllabus, objectives, prerequisites: String
    - curriculum_unit_type_id: Integer (ver DOC)
    - passing_grade: Float
    - working_hours: Integer
  3. Se for uma disciplina com curriculum_unit_type_id sendo 3 (livre), é criado um curso associado. Portanto, na resposta, é informado o id do curso. Para os demais tipos, course_id será nil.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { ok: :ok }

5. Lista de disciplinas
-----------------------

Objetivo
~~~~~~~~
  Retorna a lista de disciplinas de acordo com o semestre, tipo e curso.

Chamada
~~~~~~~
  GET disciplines

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     semester: "2014.2",
     course_type_id: 1,
     course_id: 1
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - semester: String
  2. Parâmetros opcionais
    - course_type_id: Integer (ver DOC)
    - course_id: Integer (id do curso desejado)
  3. As disciplinas no ambiente podem ou não, ao serem ofertadas, corresponder a um determinado curso (EX: Curso X oferta as disciplina Y, Z e W). Informando o curso (course_id), a lista de disciplinas retornadas ficará restrita àquelas que possuam ofertas com o curso em questão.
  
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

6. Lista de tipos de disciplinas
-----------------------

Objetivo
~~~~~~~~
  Retorna a lista com todos os tipos de disciplinas.

Chamada
~~~~~~~
  GET course/types

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  *Nenhuma observação.*
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1, 
        name: "Nome do tipo",
      }, {...}
    ]

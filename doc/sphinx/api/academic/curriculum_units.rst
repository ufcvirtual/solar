Disciplinas
===========

1. Lista de disciplinas pela oferta corrente
--------------------------------------------

Objetivo
~~~~~~~~
  Retornar lista de disciplinas da oferta vigente. Futuramente, poderemos especificar outra oferta.

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
        "id":"1",
        "code":"RM404",
        "name":"Introducao a Linguistica"
      }, {...}
    ]

2. Lista de disciplinas pela oferta corrente com suas respectivas turmas
------------------------------------------------------------------------

Objetivo
~~~~~~~~
  Retornar lista de disciplinas da oferta vigente com suas respectivas turmas. Futuramente, poderemos especificar outra oferta.

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
        "id":"1",
        "code":"RM404",
        "name":"Introducao a Linguistica"
        "groups":[{
            "id":"1",
            "code":"FOR",
            "semester":"2011.1"
        }, {...}]
      }, {...}
    ]

3. Criação de disciplina
------------------------

Objetivo
~~~~~~~~
  Criar uma disciplina

Chamada
~~~~~~~
  POST curriculum_unit

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     "name": "Disciplina01",
     "code": "D01",
     "curriculum_unit_type_id": 1,
     "resume": "Resumo",
     "syllabus": "Ementa",
     "prerequisites": "Pré-requisitos",
     "passing_grade": 7,
     "working_hours": 80,
     "credits": 4,
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
  3. Se for uma disciplina com curriculum_unit_type_id sendo 3 (livre), é criado um curso associado. Portanto, na resposta, é informado o id do curso. Para os demais tipos, course_id será nil.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { id: id_disciplina, course_id: id_curso }

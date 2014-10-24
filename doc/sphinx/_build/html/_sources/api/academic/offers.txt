Ofertas
=======

1. Lista de semestres
---------------------

Objetivo
~~~~~~~~
  Retorna a lista de todos os semestres.

Chamada
~~~~~~~
  GET /semesters

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

    [ { name: "2014" }, {...} ]

2. Criação de oferta/semestre
-----------------------------

Objetivo
~~~~~~~~
  Criar ofertas e/ou semestres.

Chamada
~~~~~~~
  POST /offer

Parâmetros
~~~~~~~~~~
  JSON::

    {
      name: "2015",
      offer_start: "2015-01-01",
      offer_end: "2015-12-31",
      enrollment_start: "2014-10-01",
      enrollment_end: "2014-12-31",
      course_id: 1,
      curriculum_unit_id: 2,
      curriculum_unit_code: "UC01",
      course_code: "C01"
    }  

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - name: String (nome do semestre a ser criado/buscado)
    - course_id, curriculum_unit_id: Integer (id do curso e disciplina)
    - curriculum_unit_code, course_code: String (código da disciplina e do curso)
    - offer_start, offer_end: Date (datas de início e fim da oferta)
  2. Parâmetros opcionais
    - enrollment_start, enrollment_end: Date (datas de início e fim do período de matrícula.)
  3. Se course_id for informado, não será aceito, na mesma chamada, o parâmetros course_code.
  4. Se curriculum_unit_id for informado, não será aceito, na mesma chamada, o parâmetros curriculum_unit_code.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { id: 1 }

3. Editar oferta
----------------

Objetivo
~~~~~~~~
  Editar uma oferta já existente.

Chamada
~~~~~~~
  PUT offer/:id

Parâmetros
~~~~~~~~~~
  JSON::

    { 
      offer_start: "2015-01-01",
      offer_end: "2015-12-31",
      enrollment_start: "2014-10-01",
      enrollment_end: "2014-12-31"
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer (id da disciplina em questão)
    - ao menos um dos parâmetros opcionais se faz obrigatório
  2. Parâmetros opcionais
    - offer_start, offer_end: Date (datas de início e fim da oferta)
    - enrollment_start, enrollment_end: Date (datas de início e fim do período de matrícula.)
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { ok: :ok }



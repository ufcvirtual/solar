Turmas
======

1. Lista de turmas de uma disciplina e usuário
----------------------------------------------

Objetivo
~~~~~~~~
  Retorna a lista de turmas do usuário logado e oferta corrente para a disciplina informada.

Chamada
~~~~~~~
  GET /curriculum_units/:id/groups

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*
  
Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer (id da disciplina)

Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1,
        code: "T01",
        semester: "2014"
      }, {...}
    ]

2. Aglutinação/Desaglutinação de turmas
---------------------------------------

Objetivo
~~~~~~~~
  1. Ao aglutinar duas ou mais turmas, o conteúdo das turmas secundárias é replicado à turma principal e aquelas são desativadas.
  2. Ao desaglutinar duas ou mais turmas, o conteúdo da turma principal é replicado às turmas secundárias e estas são re-ativadas.

Chamada
~~~~~~~
  GET /groups/merge

Parâmetros
~~~~~~~~~~
  JSON::

    {
      main_group: "T01",
      course: "C01",
      curriculum_unit: "UC01",
      secundary_groups: ["T02", "T03"],
      semester: "2014",
      type: true
    }  

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - main_group: String (turma principal)
    - course, curriculum_unit, semester: String (código do curso, disciplina e nome do semestre das turmas)
    - secundary_groups: Array de String (turmas secundárias)
  2. Parâmetros opcionais
    - type: Boolean (por padrão, se não for informado, é definido como true. se for verdadeiro, aglutina; se falso, desaglutina)
  3. Apenas turmas de uma mesma oferta (conjunto de semestre, curso e disciplina) podem ser aglutinadas/desaglutinadas.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { ok: :ok }

3. Lista de turmas
------------------

Objetivo
~~~~~~~~
  Retorna a lista de turmas de acordo com o tipo de disciplina, curso, disciplina e semestre informados.

Chamada
~~~~~~~
  GET /groups

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     semester: "2014.2",
     course_type_id: 1,
     course_id: 1,
     discipline_id: 2
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - semester: String
  2. Parâmetros opcionais
    - course_type_id: Integer (ver DOC)
    - course_id, discipline_id: Integer (curso e disciplina)
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      { 
        id: 1,
        code: "T01",
        offer_id: 1
      }, {...}
    ]

4. Criação de turma
-------------------

Objetivo
~~~~~~~~
  Criar uma turma.

Chamada
~~~~~~~
  POST /group

Parâmetros
~~~~~~~~~~
  JSON::

    {
      code: "T01",
      offer_id: 1,
      course_code: "C01",
      curriculum_unit_code: "UC01",
      semester: "2014",
      activate: false
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - code: String
    - offer_id: Integer (id da oferta)
    - curriculum_unit_code, course_code, semester: String (código da disciplina, do curso e nome do semestre)
  2. Parâmetros opcionais
    - activate: Boolean (por padrão, se não for informado, é definido como falso. se for verdadeiro e a turma a ser criada já existir, só ativa e não exibe erro de código já existente; se falso e turma já existir, exibe erro)
  3. Se offer_id for informado, não será aceito, na mesma chamada, os parâmetros curriculum_unit_code, course_code, semester.
  4. Se algum dos parâmetros curriculum_unit_code, course_code, semester for informado, não será aceito, na mesma chamada, o parâmetro offer_id.
  5. Se algum dos parâmetros curriculum_unit_code, course_code, semester for informado, se faz obrigatório que os outros dois também o sejam.
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { id: 1 }


5. Edição de turma
------------------

Objetivo
~~~~~~~~
  Editar uma turma já existente.

Chamada
~~~~~~~
  PUT group/:id

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     code: "T01",
     status: true
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer (id da turma em questão)
    - ao menos um dos parâmetros opcionais se faz obrigatório
  2. Parâmetros opcionais
    - code: String
    - status: Boolean (se true, a turma é ativada; se false, a turma é desativada)
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { ok: :ok }


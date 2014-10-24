Cursos
======

1. Lista de disciplinas pela oferta corrente
--------------------------------------------

Objetivo
~~~~~~~~
  Retorna a lista de cursos a partir do semestre e do tipo de disciplina informado.

Chamada
~~~~~~~
  GET /curriculum_units/

Parâmetros
~~~~~~~~~~
  JSON::

    {
      semester: "2014",
      course_type_id: 1
    }
  
Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - semester: String
  2. Parâmetros opcionais
    - course_type_id: Integer (ver DOC)
  3. As disciplinas no ambiente podem ou não, ao serem ofertadas, corresponder a um determinado curso (EX: Curso X oferta as disciplina Y, Z e W). Informando o tipo de disciplina (course_type_id), serão buscados os cursos que ofertam disciplinas deste tipo. 
  4. Serão buscados os cursos que estão sendo ofertados no semestre informado (semester).

Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    [
      {
        id: 1,
        code: "C01",
        name: "Curso 01"
      }, {...}
    ]

2. Criação de curso
------------------------

Objetivo
~~~~~~~~
  Criar um curso.

Chamada
~~~~~~~
  POST course

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     name: "Curso01",
     code: "C01"
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - name: String
    - code: String (máximo de 40 caracteres)
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { id: 1 }

3. Edição de curso
-------------------

Objetivo
~~~~~~~~
  Editar um curso já existente.

Chamada
~~~~~~~
  PUT course/:id

Parâmetros
~~~~~~~~~~
  JSON::

    { 
     name: "Curso01",
     code: "C01"
    }

Observações
~~~~~~~~~~~
  1. Parâmetros obrigatórios
    - id: Integer (id do curso em questão)
    - ao menos um dos parâmetros opcionais se faz obrigatório
  2. Parâmetros opcionais
    - name, code: String
  
Resposta
~~~~~~~~
  Status: 200 OK

  JSON::

    { ok: :ok }

# language: pt
Funcionalidade: Exibir tela de matricula
  Como um usuário do solar
  Eu quero acessar a listagem de unidades curriculares
  Para verificar e alterar matricula

Contexto:
    Dado que tenho "profiles"
        | id | name  | student |
        | 1  | ALUNO | true    |
    Dado que tenho "courses"
        | id | name                    | code   |
        | 1  | Letras Português        | LLPT   |
        | 2  | Licenciatura em Química | LQUIM  |
    Dado que tenho "curriculum_unit_types"
        | id | description              | allows_enrollment |
        | 1  | Graduação Presencial     | TRUE              |
        | 2  | Grad. Semipresencial     | FALSE             |
        | 3  | Curso Livre              | TRUE              |
        | 4  | Curso de Extensão        | TRUE              |
        | 5  | Pós Grad. Presencial     | TRUE              |
        | 6  | Pós Grad. Semipresencial | FALSE             |
    Dado que tenho "curriculum_units"
        | id | name                     | code  | curriculum_unit_types_id |
        | 1  | Introducao a Linguistica | RM404 | 3                        |
        | 2  | Teoria da Literatura I   | RM405 | 1                        |
        | 3  | Quimica I                | RM301 | 2                        |
        | 4  | Semipresencial sm nvista | TS101 | 2                        |
        | 5  | Literatura Brasileira I  | RM414 | 5                        |
    Dado que tenho "offers"
        | id | curriculum_units_id | courses_id | semester | start      | end        |
        | 1  | 1                   | 1          | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 2  | 2                   | 1          | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 3  | 3                   | 2          | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 4  | 4                   | 1          | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 5  | 5                   | 2          | 2011.1   | 2011-06-01 | 2021-12-01 |
    Dado que tenho "groups"
        | id | offers_id | code  | status |
        | 1  | 1         | FOR   | TRUE   |
        | 2  | 2         | CAU-A | TRUE   |
        | 3  | 3         | CAU-B | TRUE   |
        | 4  | 4         | FOR   | TRUE   |
        | 5  | 5         | FOR   | TRUE   |
    Dado que tenho "enrollments"
        | id | offers_id | start      | end        |
        | 1  | 1         | 2011-03-01 | 2021-05-30 |
        | 2  | 2         | 2011-03-01 | 2021-05-30 |
        | 3  | 3         | 2011-03-01 | 2021-05-30 |
        | 4  | 4         | 2011-03-01 | 2021-05-30 |
        | 5  | 5         | 2011-03-01 | 2021-05-30 |
    Dado que tenho "allocation_tags"
        | id | groups_id |
        | 1  | 1         |
        | 2  | 2         |
        | 3  | 3         |
        | 4  | 5         |

    Dado que tenho "allocations"
        | users_id | allocation_tags_id | profiles_id | status |
        | 1        | 1                  | 1           | 1      |
        | 1        | 3                  | 1           | 1      |
        | 1        | 4                  | 1           | 0      |

Cenário: Acessar página de matricula
    Dado que estou logado com o usuario "user" e com a senha "user123"
    Quando eu clicar no link "Matrícula"
    Então eu deverei ver "Matrícula"
        E eu deverei ver "Unidade Curricular"
        E eu deverei ver "Categoria"
        E eu deverei ver "Turma"
        E eu deverei ver "Buscar"
        E eu deverei ver "Todos"
        E eu deverei ver "Matriculados"

Cenário: Listar cursos matriculados ou disponíveis
    Dado que estou logado com o usuario "user" e com a senha "user123"
    Quando eu clicar no link "Matrícula"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria             | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre           |	FOR    | Cancelar        |
      | Literatura Brasileira I       | Pós Grad. Presencial  | FOR    | Cancelar pedido |
      | Quimica I                     | Grad. Semipresencial  | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Graduação Presencial  | CAU-A  | Matricular      |
      E eu nao deverei ver a linha de opcao de matricula
	   | UnidadeCurricular             | Categoria             | Turma  | Matricula   |
	   | Semipresencial sm nvista      | Grad. Semipresencial  | FOR    | Matricular  |

Cenário: Pedir cancelamento de matricula
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Cancelar" do item de matricula "Introducao a Linguistica"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria             | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre           |	FOR    | Matricular      |
      | Literatura Brasileira I       | Pós Grad. Presencial  | FOR    | Cancelar pedido |
      | Quimica I                     | Grad. Semipresencial  | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Graduação Presencial  | CAU-A  | Matricular      |

Cenário: Pedir matricula em curso disponível
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Matricular" do item de matricula "Teoria da Literatura I"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria             | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre           |	FOR    | Cancelar        |
      | Literatura Brasileira I       | Pós Grad. Presencial  | FOR    | Cancelar pedido |
      | Quimica I                     | Grad. Semipresencial  | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Graduação Presencial  | CAU-A  | Cancelar pedido |

Cenário: Cancelar pedido de matricula
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Cancelar pedido" do item de matricula "Literatura Brasileira I"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria             | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre           |	FOR    | Cancelar        |
      | Literatura Brasileira I       | Pós Grad. Presencial  | FOR    | Matricular      |
      | Quimica I                     | Grad. Semipresencial  | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Graduação Presencial  | CAU-A  | Matricular      |

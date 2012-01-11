# language: pt
Funcionalidade: Exibir tela de matricula
  Como um usuário do solar
  Eu quero acessar a listagem de unidades curriculares
  Para verificar e alterar matricula

Contexto:
#    Dado que tenho "courses"
#        | id | name                    | code   |
#        | 1  | Letras Português        | LLPT   |
#        | 2  | Licenciatura em Química | LQUIM  |
#    Dado que tenho "enrollments"
#        | id | offer_id  | start      | end        |
#        | 1  | 1         | 2011-03-01 | 2021-05-30 |
#        | 2  | 2         | 2011-03-01 | 2021-05-30 |
#        | 3  | 3         | 2011-03-01 | 2021-05-30 |
#        | 4  | 4         | 2011-03-01 | 2021-05-30 |
#        | 5  | 5         | 2011-03-01 | 2021-05-30 |
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 1                  | 1           | 1      |
        | 1        | 3                  | 1           | 1      |
        | 1        | 8                  | 1           | 0      |
        | 1        |                    | 12          | 1      |

@javascript
Cenário: Acessar página de matricula
    Dado que estou logado com o usuario "user" e com a senha "123456"
    Quando eu clicar no link de conteudo "Matrícula"
    Então eu deverei visualizar "Matrícula"
        E eu deverei visualizar "Unidade Curricular"
        E eu deverei visualizar "Categoria"
        E eu deverei visualizar "Turma"
        E eu deverei visualizar "Buscar"
        E eu deverei visualizar "Todos"
        E eu deverei visualizar "Matriculados"

@wip @javascript
Cenário: Listar cursos matriculados ou disponíveis
    Dado que estou logado com o usuario "user" e com a senha "123456"
    Quando eu clicar no link de conteudo "Matrícula"
    Então eu deverei visualizar a linha de opcao de matricula
      | UnidadeCurricular             | Categoria                           | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre                         | FOR    | Cancelar        |
      | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | FOR    | Cancelar pedido |
      | Quimica I                     | Curso de Graduacao a Distancia      | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Curso de Graduacao Presencial       | CAU-A  | Matricular      |
      E eu nao deverei visualizar a linha de opcao de matricula
	   | UnidadeCurricular             | Categoria                           | Turma  | Matricula   |
	   | Semipresencial sm nvista      | Curso de Pos-Graduacao a Distancia  | FOR    | Matricular  |

Cenário: Pedir cancelamento de matricula
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Cancelar" do item de matricula "Introducao a Linguistica"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria                           | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre                         | FOR    | Matricular      |
      | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | FOR    | Cancelar pedido |
      | Quimica I                     | Curso de Graduacao a Distancia      | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Curso de Graduacao Presencial       | CAU-A  | Matricular      |

Cenário: Pedir matricula em curso disponível
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Matricular" do item de matricula "Teoria da Literatura I"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria                           | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre                         | FOR    | Cancelar        |
      | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | FOR    | Cancelar pedido |
      | Quimica I                     | Curso de Graduacao a Distancia      | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Curso de Graduacao Presencial       | CAU-A  | Cancelar pedido |

Cenário: Cancelar pedido de matricula
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Matricula"
    Quando eu clicar na opcao "Cancelar pedido" do item de matricula "Literatura Brasileira I"
    Então eu deverei ver a linha de opcao de matricula
      | UnidadeCurricular             | Categoria                           | Turma  | Matricula       |
      | Introducao a Linguistica      | Curso Livre                         | FOR    | Cancelar        |
      | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | FOR    | Matricular      |
      | Quimica I                     | Curso de Graduacao a Distancia      | CAU-B  | Matriculado     |
      | Teoria da Literatura I        | Curso de Graduacao Presencial       | CAU-A  | Matricular      |

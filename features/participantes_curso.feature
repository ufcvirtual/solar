## language: pt
#Funcionalidade: Exibir participantes do curso
#  Como um usuario do solar
#  Eu quero visualizar os participantes do curso
#
#Contexto:
#    Dado que tenho "profiles"
#        | id | name              | student | class_responsible |
#        |  1 | ALUNO             | true    | false             |
#        |  2 | PROFESSOR TITULAR | false   | true              |
#        |  3 | TUTOR             | false   | true              |
##    Dado que tenho "courses"
##        | id | name                    | code   |
##        | 1  | Letras Português        | LLPT   |
##        | 2  | Licenciatura em Química | LQUIM  |
#    Dado que tenho "curriculum_unit_types"
#        | id | description              | allows_enrollment |
#        | 1  | Graduação Presencial     | TRUE              |
#        | 2  | Grad. Semipresencial     | FALSE             |
#        | 3  | Curso Livre              | TRUE              |
#        | 4  | Curso de Extensão        | TRUE              |
#        | 5  | Pós Grad. Presencial     | TRUE              |
#        | 6  | Pós Grad. Semipresencial | FALSE             |
#    Dado que tenho "curriculum_units"
#        | id | name                     | code  | curriculum_unit_types_id |
#        | 1  | Introducao a Linguistica | RM404 | 3                        |
#        | 2  | Teoria da Literatura I   | RM405 | 1                        |
#        | 3  | Quimica I                | RM301 | 2                        |
#        | 4  | Semipresencial sm nvista | TS101 | 2                        |
#        | 5  | Literatura Brasileira I  | RM414 | 5                        |
#    Dado que tenho "offers"
#        | id | curriculum_units_id | courses_id | semester | start      | end        |
#        | 1  | 1                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
#        | 2  | 2                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
#        | 3  | 3                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
#        | 4  | 4                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
#        | 5  | 5                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
#    Dado que tenho "groups"
#        | id | offers_id | code  | status |
#        | 1  | 1         | FOR   | TRUE   |
#        | 2  | 2         | CAU-A | TRUE   |
#        | 3  | 3         | CAU-B | TRUE   |
#        | 4  | 4         | FOR   | TRUE   |
#        | 5  | 5         | FOR   | TRUE   |
##    Dado que tenho "enrollments"
##        | id | offers_id | start      | end        |
##        | 1  | 1         | 2011-03-01 | 2021-05-30 |
##        | 2  | 2         | 2011-03-01 | 2021-05-30 |
##        | 3  | 3         | 2011-03-01 | 2021-05-30 |
##        | 4  | 4         | 2011-03-01 | 2021-05-30 |
##        | 5  | 5         | 2011-03-01 | 2021-05-30 |
#    Dado que tenho "allocation_tags"
#        | id | groups_id |
#        | 1  | 1         |
#        | 2  | 2         |
#        | 3  | 3         |
#        | 4  | 5         |
#    Dado que tenho "allocations"
#        | users_id | allocation_tags_id | profiles_id | status |
#        | 1        | 1                  | 1           | 1      |
#        | 1        | 3                  | 1           | 1      |
#        | 1        | 4                  | 1           | 0      |
#        | 2        | 1                  | 2           | 1      |
#        | 3        | 1                  | 3           | 1      |
#
##@wip
##Cenário: Acessar pagina de informacoes do curso
##    Dado que estou logado com o usuario "user" e com a senha "user123"
##        E que estou em "Pagina inicial do curso" referente a "1"
##        Quando eu clicar no link "Informacoes"
##    Então eu deverei ver "Ementa"
##        E eu deverei ver "Problemas formais"
##        E eu deverei ver "Objetivos"
##        E eu deverei ver "Problemas formais"
##        E eu deverei ver "Pré-requisitos"
##        E eu deverei ver "Problemas formais"
##        E eu deverei ver "Resumo"
##        E eu deverei ver "Problemas formais"
##        E eu deverei ver "Período"
##        E eu deverei ver "06/04/2011"
##        E eu deverei ver "Média"
##        E eu deverei ver "7"
##        E eu deverei ver "Responsáveis"
##        E eu deverei ver "Ricardo Palacio (PROFESSOR TITULAR)"
##        E eu deverei ver "Usuario Sobrenome (TUTOR)"

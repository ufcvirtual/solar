# language: pt
Funcionalidade: Exibir aulas de curso
  Como um usuario do solar
  Eu quero visualizar as aulas do curso
  Para poder acessá-las

Contexto:
    Dado que tenho "profiles"
        | id | name              | student | class_responsible |
        |  1 | ALUNO             | true    | false             |
        |  2 | PROFESSOR TITULAR | false   | true              |
        |  3 | TUTOR             | false   | true              |
    Dado que tenho "curriculum_unit_types"
        | id | description              | allows_enrollment |
        | 1  | Graduação Presencial     | TRUE              |
        | 2  | Grad. Semipresencial     | FALSE             |
        | 3  | Curso Livre              | TRUE              |
        | 4  | Curso de Extensão        | TRUE              |
        | 5  | Pós Grad. Presencial     | TRUE              |
        | 6  | Pós Grad. Semipresencial | FALSE             |
    Dado que tenho "curriculum_units"
        | id | name                     | code  | curriculum_unit_types_id | syllabus           | objectives        | prerequisites     | resume            | passing_grade |
        | 1  | Introducao a Linguistica | RM404 | 3                        | Problemas formais  | Problemas formais | Problemas formais | Problemas formais | 7.0           |
        | 2  | Teoria da Literatura I   | RM405 | 1                        | Problemas formais  | Problemas formais | Problemas formais | Problemas formais | 7.0           |
        | 3  | Quimica I                | RM301 | 2                        | Problemas formais  | Problemas formais | Problemas formais | Problemas formais | 7.0           |
        | 4  | Semipresencial sm nvista | TS101 | 2                        | Problemas formais  | Problemas formais | Problemas formais | Problemas formais | 7.0           |
        | 5  | Literatura Brasileira I  | RM414 | 5                        | Problemas formais  | Problemas formais | Problemas formais | Problemas formais | 7.0           |
    Dado que tenho "offers"
        | id | curriculum_units_id | courses_id | semester | start      | end        |
        | 1  | 1                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 2  | 2                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 3  | 3                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 4  | 4                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 5  | 5                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
    Dado que tenho "groups"
        | id | offers_id | code  | status |
        | 1  | 1         | FOR   | TRUE   |
        | 2  | 2         | CAU-A | TRUE   |
        | 3  | 3         | CAU-B | TRUE   |
        | 4  | 4         | FOR   | TRUE   |
        | 5  | 5         | FOR   | TRUE   |    
    Dado que tenho "allocation_tags"
        | id | offers_id |
        | 1  | 1         |    
    Dado que tenho "allocations"
        | users_id | allocation_tags_id | profiles_id | status |
        | 1        | 1                  | 2           | 1      |
        | 2        | 1                  | 1           | 1      |
        | 3        | 1                  | 1           | 1      |
    Dado que tenho "lessons"
        | id | users_id | allocation_tags_id | name           | address                 | type_lesson | order | status | start      | end        |
        | 1  | 1        | 1                  | aula 1 pag ufc | http://www.uol.com.br   | 1           | 1     | 1      | 2011-03-01 | 2021-12-01 |
        | 2  | 1        | 1                  | aula 2 pag uol | http://opovo.uol.com.br | 1           | 2     | 1      | 2011-03-01 | 2021-12-01 |


Cenário: Exibir aulas do curso
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
    Quando eu clicar em "Introducao a Linguistica"
        Então eu deverei ver "Aulas"
    Quando eu clicar no link "Aulas"
    Então eu deverei ver "Aulas"
        E eu deverei ver o link "aula 1 pag ufc"
        E eu deverei ver o link "aula 2 pag uol"

#Cenário: Acessar aula do curso
#    Dado que estou logado com o usuario "user" e com a senha "user123"
#        E que estou em "Meu Solar"
#    Quando eu clicar em "Introducao a Linguistica"
#        Então eu deverei ver "Aulas"
#    Quando eu clicar no link "Aulas"
#        Então eu deverei ver o link "aula 1 pag ufc"
#    Quando eu clicar no link "aula 1 pag ufc"
#        Então eu deverei ver "cabeçalho"

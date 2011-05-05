#language: pt

Funcionalidade: Portlet de unidades curriculares
  Como um usuário do solar
  Eu quero ver minha lista de unidades curriculares num portlet do home
  Para ter acesso rápido a suas páginas e atividades.

Contexto:
    Dado que tenho "courses"
        | name                    | code   |
        | Letras Português        | LLPT   |
        | Licenciatura em Química | LQUIM  |
#    Dado que tenho "offers"
#        | curriculum_units_id | courses_id | semester | start      | end        |
#        | 1                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
#        | 2                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
#        | 3                   | 2          | 2011.1   | 2011-06-01 | 2011-12-01 |
#        | 4                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
#    Dado que tenho "groups"
#        | offers_id | code  | status |
#        | 1         | FOR   | TRUE   |
#        | 2         | CAU-A | TRUE   |
#        | 3         | CAU-B | TRUE   |
#        | 4         | FOR   | TRUE   |
    Dado que tenho "enrollments"
        | offers_id | start      | end        |
        | 1         | 2011-03-01 | 2011-05-30 |
        | 2         | 2011-03-01 | 2011-05-30 |
        | 3         | 2011-03-01 | 2011-05-30 |
        | 4         | 2011-03-01 | 2011-05-30 |
#    Dado que tenho "allocation_tags"
#        | id | groups_id |
#        | 1  | 1         |
#        | 2  | 2         |
#        | 3  | 3         |
#        | 4  | 4         |
#
    Dado que tenho "allocations"
        | users_id | allocation_tags_id | profiles_id | status |
        | 1        | 1                  | 1           | 1      |
        | 1        | 2                  | 1           | 1      |
        | 2        | 3                  | 1           | 1      |
        | 2        | 4                  | 1           | 1      |

Cenário: Acessar página do meuSolar e visualizar o Portlet de unidades curriculares
	Dado que estou logado com o usuario "user" e com a senha "user123"
            E que estou em "Meu Solar"
	Então eu deverei ver "Unidades Curriculares"
            E eu deverei ver o botao "Introducao a Linguistica"
            E eu deverei ver o botao "Teoria da Literatura I"
            E eu nao deverei ver "Quimica I"
            E eu nao deverei ver "Semipresencial sm nvista"
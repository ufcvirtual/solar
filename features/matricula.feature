# language: pt
Funcionalidade: Exibir tela de matricula
  Como um usuário do solar
  Eu quero acessar a listagem de unidades curriculares
  Para verificar e alterar matricula

Contexto:
    Dado que tenho "users"
	| id | login | email		       | password | name   | birthdate  | cpf         | sex  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    | bio                                                     | interests     | music                                                 | movies                      | books        | phrase         | site                      |
	| 1  | user  | teste@virtual.ufc.br | user123  | User01 | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com | vencedor do torneio nordestão de counter strike em 2005 | sushi, festas | Jurandi Vieira, Dream Theather, Calypso, Eric Clapton | O homem de desafiou o Diabo | Harry Potter | Bato ou corro! | www.jacarebanguela.com.br |
    Dado que tenho "personal_configurations"
        | user_id | default_locale |
        | 1       | pt-BR |

    Dado que tenho "profiles"
        | name  | 
        | ALUNO |
    Dado que tenho "courses"
        | name                    | code   |
        | Letras Português        | LLPT   |
        | Licenciatura em Química | LQUIM  |
    Dado que tenho "curriculum_units"
        | name                     | code  | category |
        | Introdução à Linguística | RM404 | 3        |
        | Teoria da Literatura I   | RM405 | 2        |
        | Química I                | RM301 | 5        |
        | Semipresencial sm nvista | TS101 | 3        |
    Dado que tenho "offers"
        | curriculum_units_id | courses_id | semester | start      | end        |
        | 1                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
        | 2                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
        | 3                   | 2          | 2011.1   | 2011-06-01 | 2011-12-01 |
        | 4                   | 1          | 2011.1   | 2011-06-01 | 2011-12-01 |
    Dado que tenho "groups"
        | offers_id | code  | status |
        | 1         | FOR   | TRUE   |
        | 2         | CAU-A | TRUE   |
        | 3         | CAU-B | TRUE   |
        | 4         | FOR   | TRUE   |
    Dado que tenho "enrollments"
        | offers_id | start      | end        |
        | 1         | 2011-03-01 | 2011-05-30 |
        | 2         | 2011-03-01 | 2011-05-30 |
        | 3         | 2011-03-01 | 2011-05-30 |
        | 4         | 2011-03-01 | 2011-05-30 |
    Dado que tenho "allocations"
        | users_id | groups_id | profiles_id | status |
        | 1        | 1         | 1           | 1      |
        | 1        | 2         | 1           | 1      |

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

@wip
Cenário: Listar cursos matriculados ou disponíveis
    Dado que estou logado com o usuario "user" e com a senha "user123"
    Quando eu clicar no link "Matrícula"
    Então eu deverei ver a tabela
      | Unidade Curricular            | Categoria             | Turma  | Matrícula   |
      | Introdução à Linguística      | Grad. Semipresencial  |	FOR    | Matriculado |
      | Química I                     | Pós-Grad. Presencial  | CAU-B  | Matricular  |
      | Teoria da Literatura I        | Curso Livre           | CAU-A  | Matricular  |
#      E eu não deverei ver a tabela
#      | Unidade Curricular            | Categoria             | Turma  | Matrícula   |
#      | Semipresencial sm nvista      | Grad. Semipresencial | Matricular|

#Esquema do Cenário: Realizacao de matricula
#    Dado que estou logado com o usuario "user" e com a senha "user123"
#    E que estou em "Matricula"
#	Quando eu clicar em "Matricular"
#	Então eu deverei ver "<action>"
#Exemplos:
#	| login         |  password       |   action  		   |
#	| user          |  user123        | Novidades 		   |
#	| unknown_user  |  any_password   | Dados de login incorretos! |
#	| user          |  wrong_password | Dados de login incorretos! |
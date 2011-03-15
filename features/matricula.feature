# language: pt
Funcionalidade: Exibir tela de matricula
  Como um usuário do solar
  Eu quero acessar a listagem de unidades curriculares
  Para verificar e alterar matricula

Contexto:
    Dado que tenho "users"
	| login | email		       | password | name   | birthdate  | cpf         | sex  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    | bio                                                     | interests     | music                                                 | movies                      | books        | phrase         | site                      |
	| user  | teste@virtual.ufc.br | user123  | User01 | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com | vencedor do torneio nordestão de counter strike em 2005 | sushi, festas | Jurandi Vieira, Dream Theather, Calypso, Eric Clapton | O homem de desafiou o Diabo | Harry Potter | Bato ou corro! | www.jacarebanguela.com.br |
    Dado que tenho "profiles"
        | name  | 
        | ALUNO |
    Dado que tenho "courses"
        | name                    | code   |
        | Letras Português        | LLPT   |
        | Licenciatura em Química | LQUIM  |
    Dado que tenho "curriculum_units"
        | name                     | code  | category |
        | Química I                | RM301 | 5        |
        | Introdução à Linguística | RM404 | 1        |
        | Teoria da Literatura I   | RM405 | 2        |
    Dado que tenho "offers"
        | curriculum_units_id | courses_id | semester | start      | end        |
        | 1                   | 1          | 2011.1   | 2011-02-01 | 2011-03-20 |
        | 2                   | 1          | 2011.1   | 2011-03-10 | 2011-04-01 |
        | 3                   | 2          | 2011.1   | 2011-03-10 | 2011-04-01 |
    Dado que tenho "groups"
        | offers_id | code  | status |
        | 1         | FOR   | TRUE   |
        | 2         | CAU-A | TRUE   |
    Dado que tenho "enrollments"
        | offers_id | start      | end        |
        | 1         | 2011-01-01 | 2011-03-02 |
        | 2         | 2011-03-03 | 2011-03-03 |
        | 3         | 2011-03-02 | 2011-03-10 |
#    Dado que tenho "allocations"
#        | users_id | groups_id | profiles_id | status |
#        | 1        | 1         | 1           | 1      |

@wip
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

#Cenário: Listar todos cursos matriculados ou disponíveis
#    Dado que
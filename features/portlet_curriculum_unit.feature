#language: pt

Funcionalidade: Portlet de unidades curriculares
  Como um usuário do solar
  Eu quero ver minha lista de unidades curriculares num portlet do home
  Para ter acesso rápido a suas páginas e atividades.


Contexto:
    Dado que tenho "users"
        | id | login | email		       | password | name   | birthdate  | cpf         | gender  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    | bio                                                     | interests     | music                                                 | movies                      | books        | phrase         | site                      |
        | 1  | user  | teste@virtual.ufc.br    | user123  | User01 | 01/01/2005 | 78218921494 | true    | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com | vencedor do torneio nordestão de counter strike em 2005 | sushi, festas | Jurandi Vieira, Dream Theather, Calypso, Eric Clapton | O homem de desafiou o Diabo | Harry Potter | Bato ou corro! | www.jacarebanguela.com.br |
        | 2  | usr2  | teste2@irtual.ufc.br    | user222  | User02 | 01/01/2005 | 23885393905 | true    | Rua B   | 333            | Jose Walter          | 500000000 | Brasil  | CE    | Fortaleza | UFC         | outrmail@gmail.com | corinthiano desde muleque ia ao estadio com seu brother brunuh | timao  | Restart, Metalica e Exaltassamba                      | Senhor do anel              | Biblia       | Timao eeeoo!!! | timao.com |

    Dado que tenho "personal_configurations"
        | user_id | default_locale |
        | 1       | pt-BR |
        | 2       | pt-BR |

    Dado que tenho "profiles"
        | name      |
        | ALUNO     |
        | PROFESSOR |
    Dado que tenho "courses"
        | name                    | code   |
        | Letras Português        | LLPT   |
        | Licenciatura em Química | LQUIM  |
    Dado que tenho "curriculum_unit_types"
        | description              | allows_enrollment |
        | Graduação Presencial     | TRUE              |
        | Grad. Semipresencial     | FALSE             |
        | Curso Livre              | TRUE              |
        | Curso de Extensão        | TRUE              |
        | Pós Grad. Presencial     | TRUE              |
        | Pós Grad. Semipresencial | FALSE             |
    Dado que tenho "curriculum_units"
        | name                     | code  | curriculum_unit_types_id |
        | Introdução à Linguística | RM404 | 3                        |
        | Teoria da Literatura I   | RM405 | 1                        |
        | Química I                | RM301 | 2                        |
        | Semipresencial sm nvista | TS101 | 2                        |
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
    Dado que tenho "allocation_tags"
        | id | groups_id |
        | 1  | 1         |
        | 2  | 2         |
        | 3  | 3         |
        | 4  | 4         |

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
            E eu deverei ver "Introdução à Linguística"
            E eu deverei ver "Teoria da Literatura I"
            E eu nao deverei ver "Química I"
            E eu nao deverei ver "Semipresencial sm nvista"
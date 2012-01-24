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
    Dado que tenho "enrollments"
        | offer_id  | start      | end        |
        | 1         | 2011-03-01 | 2011-05-30 |
        | 2         | 2011-03-01 | 2011-05-30 |
        | 3         | 2011-03-01 | 2011-05-30 |
        | 4         | 2011-03-01 | 2011-05-30 |
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 1                  | 1           | 1      |
        | 1        | 2                  | 1           | 1      |
        | 1        |                    | 12          | 1      |
        | 2        | 3                  | 1           | 1      |
        | 2        | 4                  | 1           | 1      |
        | 2        |                    | 12          | 1      |

Cenário: Acessar página do meuSolar e visualizar o Portlet de unidades curriculares
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Meu Solar"
	Então eu deverei ver "Unidade Curricular"
            E eu deverei ver "Introducao a Linguistica"
            E eu deverei ver "Teoria da Literatura I"
            E eu nao deverei ver "Quimica I"
            E eu nao deverei ver "Semipresencial sm nvista"
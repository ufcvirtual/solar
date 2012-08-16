# language: pt

Funcionalidade: Acessar Unidade Curricular
  Como um usuario do solar
  Eu quero visualizar os dados da página de uma unidade curricular

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 1        | 1                  | 3           | 1      |
    | 2        | 1                  | 2           | 1      |

Cenário: Acessar pagina de unidade curricular
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
    Quando eu clicar no link "Introducao a Linguistica"
    Entao eu deverei ver a migalha de pao "Home" > "Introducao a Linguistica"
    E eu deverei ver "Unidade Curricular"
    E eu deverei ver "Responsáveis"
    E eu deverei ver "Aulas"
    E eu deverei ver "Mensagens"
    E eu deverei ver "Fórum"
    E eu deverei ver "Agenda"
    E eu deverei ver o link "Conteúdo"
    E eu deverei ver o link "Atividades"
    E eu deverei ver o link "Informações Gerais"
    E eu deverei ver o link "Mensagens"
    E eu deverei ver o link "Matrícula"


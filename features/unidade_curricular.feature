# language: pt

Funcionalidade: Acessar Unidade Curricular
  Como um usuario do solar
  Eu quero visualizar os dados da página de uma unidade curricular

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 1        | 1                  | 3           | 1      |
    | 2        | 1                  | 2           | 1      |

@javascript
Cenário: Acessar pagina de unidade curricular
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "RM404 - Introducao a Linguistica" em "td.course"
  Entao eu deverei ver a migalha de pao "Home" > "Introducao A Linguistica - 2011.1"
    E eu deverei ver "Unidade Curricular"
    E eu deverei ver "Responsáveis"
    E eu deverei ver "Aulas"
    E eu deverei ver "Mensagens"
    E eu deverei ver "Fórum"
    E eu deverei ver "Agenda"
    E eu deverei ver "Conteúdo"
    E eu deverei ver "Atividades"
    E eu deverei ver "Informações Gerais"
    E eu deverei ver o link "Mensagens"
    E eu deverei ver o link "Matrícula"

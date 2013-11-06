# language: pt

Funcionalidade: Exibir Material de apoio
  Como um usuario do solar
  Eu quero visualizar o material de apoio
  Para poder acessá-las

Contexto:
Dado que tenho "allocations"
  | user_id | allocation_tag_id | profile_id | status |
  |    7    |         1         |     5      |    1   |
  |    7    |         2         |     5      |    1   |
  |    7    |         3         |     5      |    1   |

Cenário: Exibir Material de apoio
   Dado que estou logado com o usuario "user" e com a senha "123456"
   E que estou em "Meu Solar"
       Quando eu clicar no link "Quimica I"
   Então eu deverei ver "Conteúdo"
       Quando eu clicar no link "Conteúdo"
   Então eu deverei ver o link "Material de Apoio"
       Quando eu clicar no link "Material de Apoio"
   Então eu deverei ver "AULAS"
      E eu deverei ver o link "2.pdf"
      E eu deverei ver "LINKS"
      E eu deverei ver o link "http://www.google.com"
      E eu deverei ver "OUTRA PASTA"
      E eu deverei ver o link "3.pdf"

#COMBOBOX-TESTE1
@javascript
Cenário: Trocar material de apoio com a combo
    Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
        Quando eu clicar no link "Introducao a Linguistica"
    E que eu selecionei "selected_group" com "FOR - 2012.1"
    Então eu deverei ver "Conteúdo"
        Quando eu clicar no link "Conteúdo"
    Então eu deverei ver o link "Material de Apoio"
        Quando eu clicar no link "Material de Apoio"
            Então eu deverei ver "AULAS"
            E eu deverei ver o link "1.pdf"

#COMBOBOX-TESTE2
@javascript
Cenário: Trocar material de apoio com a combo - parte 2
    Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
        Quando eu clicar no link "Introducao a Linguistica"
    E que eu selecionei "selected_group" com "FOR - 2011.1"
    Então eu deverei ver "Conteúdo"
        Quando eu clicar no link "Conteúdo"
    Então eu deverei ver o link "Material de Apoio"
        Quando eu clicar no link "Material de Apoio"
            Então eu deverei ver "AULAS"
            E eu deverei ver o link "1.jpg"


####### EDITOR ########

#Cenário: Exibir Material de apoio para o editor e parte superior de upload
#  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
#  E que estou em "Meu Solar"
#   Então eu deverei ver o link "Material de Apoio do Editor"
#       Quando eu clicar no link "Material de Apoio do Editor"
#       Então eu deverei ver "Link:"
#           E eu deverei ver "Pasta:"
#           E eu deverei ver "Arquivo:"
#           E eu deverei ver "LINKS"
#           E eu deverei ver o link "http://www.google.com"
#           E eu deverei ver "OUTRA PASTA"
#           E eu deverei ver o link "3.pdf"

#Cenário: Upload de arquivos pelo editor
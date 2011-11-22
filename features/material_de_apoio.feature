# language: pt
Funcionalidade: Exibir Material de apoio
Como um usuario do solar
Eu quero visualizar o material de apoio
Para poder acessá-las


Contexto:
Dado que tenho "allocations"
| user_id | allocation_tag_id | profile_id | status |
|    1    |         3         |     1      |    1   |
|    1    |         1         |     1      |    1   |
|    1    |         9         |     1      |    1   |

@wip
Cenário: Exibir Material de apoio
    Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
        Quando eu clicar no link "Quimica I"
    Então eu deverei ver "Conteúdo"
        Quando eu clicar no link "Conteúdo"
    Então eu deverei ver o link "Material de Apoio"
        Quando eu clicar no link "Material de Apoio"
    Então eu deverei ver "aulas"
       E eu deverei ver o link "2.pdf"
       E eu deverei ver "fotos"
       E eu deverei ver o link "1.png"
       E eu deverei ver "outra pasta"
       E eu deverei ver o link "3.pdf"

#COMBOBOX
#@wip
#Cenário: Trocar material de apoio com a combo
#    Dado que estou logado com o usuario "user" e com a senha "123456"
#    E que estou em "Meu Solar"
#        Quando eu clicar no link "Introducao a Linguistica"
#    Então eu deverei ver "Conteúdo"
#        Quando eu clicar no link "Conteúdo"
#    Então eu deverei ver o link "Material de Apoio"
#        Quando eu clicar no link "Material de Apoio"
#            Então eu deverei ver "aulas"
#            E eu deverei ver o link "1.pdf"
#############Quando eu clicar no link "FOR - 2011.1"
#            Então eu deverei ver o link "1.pdf"

# language: pt
Funcionalidade: Exibir Portfolio
  Como um usuario do solar
  Eu quero visualizar o portfolio
  Para poder acessá-los


Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 1           | 1      |

Cenário: Exibir Portfolio
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Portfolio"
    Quando eu clicar no link "Portfolio"
        Então eu deverei ver "Portfolio"
        E eu deverei ver "Atividades Individuais"
        E eu deverei ver "Descrição"
        E eu deverei ver o link "Atividade III"
    Quando eu clicar no link "Atividade III"
        Então eu deverei ver "Atividade III"
        E eu deverei ver "Descrição"
        E eu deverei ver "Podemos já vislumbrar o modo pelo qual a crescente influência"
        E eu deverei ver "Comentários do Professor"
        E eu deverei ver "Arquivos Enviados"
        E eu deverei ver "Data"
        E eu deverei ver "Situação"
        E eu deverei ver "Nota"


#Cenário: Enviar arquivo